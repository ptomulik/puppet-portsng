# Some ancient versions of puppet were not adding modules to $LOAD_PATH
%w(vash portsutil backports).each do |p|
  dir = File.join(File.dirname(__FILE__), "../../../../../#{p}/lib")
  dir = File.expand_path(dir)
  $LOAD_PATH.unshift(dir) if !$LOAD_PATH.include?(dir) && File.directory?(dir)
end

require 'puppet/backport/type/package/package_settings'
require 'puppet/backport/type/package/uninstall_options'
require 'puppet/provider/package'

# rubocop: disable BlockLength
Puppet::Type.type(:package).provide :portsng,
                                    :parent => Puppet::Provider::Package do
  desc "Support for FreeBSD's ports. Note that this mixes packages and ports.

  `install_options` are passed to `portupgrade` command when installing,
  reinstalling or upgrading packages. You should always include
  `['-M','BATCH=yes']` options in your custom `install_options`. Some CLI flags
  are prepended internally to CLI and some flags given by user are internally
  removed when performing install, reinstall or upgrade actions. Install
  always prepends `-N` and removes `-R` and `-f` if provided by user. Reinstall
  always prepends `-f` and removes `-N` flag if present. Upgrade always removes
  `-N` and `-f` if present in install_options.

  `uninstall_options` are passed to uninstall command. When the target system
  uses (old) `pkg_xxx` tools to manage packages, these options are passed to
  `pkg_deinstall` command. When the target system uses `pkgng` tools, then
  `uninstall_options` are passed to `pkg` command. If you define custom options
  for `pkg` (pkgng toolstack), you should always include the `-y` option (see
  pkg-delete(8) for details). Typical use case for `uninstall_options` is
  uninstalling packages recursively, that is uninstalling a package and all the
  other packages depending on this one. For `pkg_deinstall` the `%w(-r)` does
  the job and for `pkgng` it's achieved with `%w(-y -R)`.

  `package_settings` shall be a hash with port's option names as keys (all
  uppercase) and boolean values. This parameter defines options that you would
  normally set with make config command (the blue ncurses interface). Here is
  an example:

      package { 'www/apache22':
        ensure => present,
        package_settings => { 'SUEXEC' => true }
      }


  The options are written to `/var/db/ports/*/options.local` files (one file
  per package). For old `pkg_xxx` toolstack they are synchronized with what is
  found in `/var/db/ports/*/options{,.local}` files (possibly several files
  files per package). For the new `pkgng` system, they're synchronized with
  options returned by `pkg query`. If `package_settings` of an already installed
  package are out of sync with the ones prescribed in puppet manifests, the
  package gets reinstalled with the options taken from puppet manifests.
  "
  require 'puppet/util/ptomulik/package/ports'
  require 'puppet/util/ptomulik/package/ports/options'
  extend Puppet::Util::PTomulik::Package::Ports

  # Default options for {#install} method.
  self::DEFAULT_INSTALL_OPTIONS = %w(-N -M BATCH=yes).freeze
  # Default options for {#reinstall} method.
  self::DEFAULT_REINSTALL_OPTIONS = %w(-r -f -M BATCH=yes).freeze
  # Default options for {#update} method.
  self::DEFAULT_UPGRADE_OPTIONS = %w(-R -M BATCH=yes).freeze

  # Detect whether the OS uses old pkg or the new pkgng.
  if pkgng_active? :pkg => '/usr/local/sbin/pkg'
    commands :portuninstall => '/usr/local/sbin/pkg',
             :pkg => '/usr/local/sbin/pkg'
    self::DEFAULT_UNINSTALL_OPTIONS = %w(delete -y).freeze
  else
    commands :portuninstall => '/usr/local/sbin/pkg_deinstall'
    self::DEFAULT_UNINSTALL_OPTIONS = %w().freeze
  end
  debug "Selecting '#{command(:portuninstall)}' command as package uninstaller"

  commands :portupgrade => '/usr/local/sbin/portupgrade',
           :portversion => '/usr/local/sbin/portversion',
           :make =>        '/usr/bin/make'

  has_feature :install_options
  has_feature :uninstall_options

  # I hate ports
  %w(INTERACTIVE UNAME).each do |var|
    ENV.delete(var) if ENV.include?(var)
  end

  # note, portsdir and port_dbdir are defined in module
  # Puppet::Util::PTomulik::Package::Ports::Functions
  confine :exists => [portsdir, port_dbdir]

  def pkgng_active?
    self.class.pkgng_active?
  end

  def self.instances(names = nil)
    records = find_packages(names, instances_fields)
    instances_from_package_records(records, query_build_options)
  end

  def self.prefetch(packages)
    # prefetch already installed packages
    absent = prefetch_present(packages)
    # also prefetch not installed ports to save time; this way we perform
    # only two or three calls to `make search` (for up to 60 packages) instead
    # of 3xN calls (in query()) for N packages
    prefetch_absent(packages, absent)
  end

  def self.instances_fields
    fields = Puppet::Util::PTomulik::Package::Ports::PkgRecord.default_fields
    fields -= [:options] if pkgng_active?
    fields
  end
  private_class_method :instances_fields

  # return build options for all installed packages (if pkgng is active)
  def self.query_build_options
    if pkgng_active?
      # here, with pkgng we have more reliable and efficient way to retrieve
      # build options
      options_class = Puppet::Util::PTomulik::Package::Ports::Options
      options_class.query_pkgng('%o', nil, :pkg => command(:pkg))
    else
      {}
    end
  end
  private_class_method :query_build_options

  def self.split_record_fcn(names)
    if names
      lambda { |r| [r[1][:pkgname], r[1]] }
    else
      lambda { |r| [r[:pkgname], r] }
    end
  end
  private_class_method :split_record_fcn

  def self.find_packages(names, fields)
    split_record = split_record_fcn(names)
    records = {}
    # find installed packages
    search_packages(names, fields) do |record|
      name, record = split_record.call(record)
      records[name] ||= []
      records[name] << record
    end
    records
  end
  private_class_method :find_packages

  def self.instance_from_package_record(record, options)
    portorigin = record[:portorigin]
    # if portorigin is unavailable, use pkgname to identify the package,
    # this allows to at least uninstall packages that are currently
    # installed but their ports were removed from ports tree
    new(:name => portorigin || record[:pkgname],
        :ensure => record[:pkgversion],
        :package_settings => options[portorigin] || record[:options] || {},
        :provider => name).assign_port_attributes(record)
  end
  private_class_method :instance_from_package_record

  def self.instances_from_package_records(records, options)
    packages = []
    with_unique('installed ports', records) do |pkgname, rec|
      unless rec[:portorigin] && ['<', '=', '>'].include?(rec[:portstatus])
        rec.delete(:portorigin) if rec[:portorigin]
        warning "Could not find port for installed package '#{pkgname}'. " \
                'Build options and upgrades will not work for this package.'
      end
      packages << instance_from_package_record(rec, options)
    end
    packages
  end
  private_class_method :instances_from_package_records

  def self.find_ports(names)
    records = {}
    search_ports(names) do |name, record|
      records[name] ||= []
      records[name] << record
    end
    records
  end
  private_class_method :find_ports

  def self.instance_from_absent_port_record(record)
    portorigin = record[:portorigin]
    new(:name => portorigin, :ensure => :absent).assign_port_attributes(record)
  end
  private_class_method :instance_from_absent_port_record

  # prefetch already installed packages and return remaining packages
  def self.prefetch_present(packages)
    absent = packages.keys
    instances.each do |prov|
      keys = [prov.name, prov.portorigin, prov.pkgname, prov.portname]
      pkg = keys.map { |x| packages[x] }.find { |x| x }
      next unless pkg
      absent -= keys
      pkg.provider = prov
    end
    absent
  end
  private_class_method :prefetch_present

  def self.prefetch_absent(packages, absent)
    with_unique('ports', find_ports(absent)) do |name, record|
      packages[name].provider = instance_from_absent_port_record(record)
    end
  end
  private_class_method :prefetch_absent

  def self.with_unique(what, records)
    records.each do |name, array|
      record = array.last
      if (len = array.length) > 1
        warning "Found #{len} #{what} named '#{name}': " \
                "#{array.map { |r| "'#{r[:portorigin]}'" }.join(', ')}. " \
                "Only '#{record[:portorigin]}' will be ensured."
      end
      yield name, record
    end
  end
  private_class_method :with_unique

  self::PORT_ATTRIBUTES = [
    :pkgname,
    :portorigin,
    :portname,
    :portstatus,
    :portinfo,
    :options_file,
    :options_files
  ].freeze

  self::PORT_ATTRIBUTES.each do |attr|
    define_method(attr) do
      var = instance_variable_get("@#{attr}".intern)
      unless var
        raise Puppet::Error,
              "Attribute '#{attr}' not assigned for package '#{name}'."
      end
      var
    end
  end

  # assign attributes from hash (but only these listed in PORT_ATTRIBUTES)
  def assign_port_attributes(record)
    (record.keys & self.class::PORT_ATTRIBUTES).each do |key|
      instance_variable_set("@#{key}".intern, record[key])
    end
    self
  end

  def validate_package_setting(key, value)
    options_class = Puppet::Util::PTomulik::Package::Ports::Options
    unless options_class.option_name?(key)
      raise ArgumentError, "#{key.inspect} is not a valid option name (for" \
                           ' $package_settings)'
    end
    unless options_class.option_value?(value)
      raise ArgumentError, "#{value.inspect} is not a valid option value (for" \
                           ' $package_settings)'
    end
    true
  end
  private :validate_package_setting

  # needed by Puppet::Type::Package
  def package_settings_validate(opts)
    return true unless opts # options not defined
    options_class = Puppet::Util::PTomulik::Package::Ports::Options
    unless opts.is_a?(Hash) || opts.is_a?(options_class)
      raise ArgumentError, "#{opts.inspect} of type #{opts.class} is not an " \
                           'options Hash (for $package_settings)'
    end
    opts.each { |k, v| validate_package_setting(k, v) }
    true
  end

  # needed by Puppet::Type::Package
  def package_settings_munge(opts)
    if opts.is_a?(Puppet::Util::PTomulik::Package::Ports::Options)
      opts
    else
      Puppet::Util::PTomulik::Package::Ports::Options[opts || {}]
    end
  end

  # needed by Puppet::Type::Package
  def package_settings_insync?(should, is)
    unless should.is_a?(Puppet::Util::PTomulik::Package::Ports::Options) &&
           is.is_a?(Puppet::Util::PTomulik::Package::Ports::Options)
      return false
    end
    is.select { |k, _| should.keys.include? k } == should
  end

  # needed by Puppet::Type::Package
  def package_settings_should_to_s(_should, newvalue)
    if newvalue.is_a?(Puppet::Util::PTomulik::Package::Ports::Options)
      Puppet::Util::PTomulik::Package::Ports::Options[newvalue.sort].inspect
    else
      newvalue.inspect
    end
  end

  # needed by Puppet::Type::Package
  def package_settings_is_to_s(should, currentvalue)
    if currentvalue.is_a?(Puppet::Util::PTomulik::Package::Ports::Options)
      hash = currentvalue.select { |k, _| should.keys.include? k }.sort
      Puppet::Util::PTomulik::Package::Ports::Options[hash].inspect
    else
      currentvalue.inspect
    end
  end

  # Interface method required by package resource type. Returns the current
  # value of package_settings property.
  def package_settings
    properties[:package_settings]
  end

  # Reinstall package to deploy (new) build options.
  def package_settings=(opts)
    reinstall(opts)
  end

  def sync_package_settings(should)
    return unless should
    is = properties[:package_settings]
    return if package_settings_insync?(should, is)
    syntax = self.class.options_files_default_syntax
    should.save(options_file, :pkgname => pkgname, :syntax => syntax)
  end
  private :sync_package_settings

  def revert_package_settings
    return unless (options = properties[:package_settings])
    debug "Reverting options in #{options_file}"
    syntax = self.class.options_files_default_syntax
    options.save(options_file, :pkgname => pkgname, :syntax => syntax)
  end
  private :revert_package_settings

  # Return portupgrade's CLI options for use within the {#install} method.
  def install_options
    # In an ideal world we would have all these parameters independent:
    # install_options, reinstall_options, upgrade_options, uninstall_options.
    # In this world we must live with install_options and uninstall_options
    # only.
    ops = resource[:install_options]
    # We always add -N to command line to indicate, that we want to install new
    # package only when it's not installed. This idea is inherited from
    # original implementation of ports provider.
    # We always remove -R and -f from command line, as these options have
    # no clear meaning when -N is used (either, they have no effect with -R or
    # they can mess-up your OS - I haven't checked this).
    prepare_options(ops, self.class::DEFAULT_INSTALL_OPTIONS, %w(-N), %w(-R -f))
  end

  # Return portupgrade's CLI options for use within the {#reinstall} method.
  def reinstall_options
    ops = resource[:install_options]
    # We always remove -N from command line, as this flag breaks the upgrade
    # procedure (-N indicates that one wants to install new package which is
    # currently not installed, or to skip installation if it's installed; the
    # reinstall method is invoked on already installed packages only).
    # We always add -f to command line, to not silently skip reinstall (without
    # this reinstalls are silently discarded)
    prepare_options(ops, self.class::DEFAULT_REINSTALL_OPTIONS, %w(-f), %w(-N))
  end

  # Return portupgrade's CLI options for use within the {#update} method.
  def upgrade_options
    ops = resource[:install_options]
    # We always remove -N from command line, as this flag breaks the upgrade
    # procedure (-N indicates that one wants to install package which is not
    # currently installed, or to skip installation if it's installed; the
    # upgrade method is invoked on already installed packages only).
    # We always remove -f from command line, as the upgrade procedure shouldn't
    # depend on it (upgrade should only be used to install newer versions,
    # which must work without -f)
    prepare_options(ops, self.class::DEFAULT_UPGRADE_OPTIONS, %w(), %w(-f -N))
  end

  # Return portuninstall's CLI options for use within the {#uninstall} method.
  def uninstall_options
    # For pkgng we always prepend the 'delete' command to options.
    ops = resource[:uninstall_options]
    if pkgng_active?
      prepare_options(ops, self.class::DEFAULT_UNINSTALL_OPTIONS, %w(delete))
    else
      prepare_options(ops, self.class::DEFAULT_UNINSTALL_OPTIONS)
    end
  end

  # Prepare options for install, reinstall, upgrade and uninstall methods.
  #
  # @param options [Array|nil]
  # @param defaults [Array] default flags used when options are not provided,
  # @param extra [Array] extra flags added to user-defined options,
  # @param deny [Array] flags that must be removed from user-defined options,
  # @return [Array] modified options
  #
  # Returns defaults if options are not provided by user. If options are
  # provided, handle the '{option => value}' pairs, flatten options array
  # append extra flags defined by caller and remove denied flags defined by the
  # caller.
  #
  def prepare_options(options, defaults, extra = [], deny = [])
    return defaults.dup unless options

    # handle {option => value} hashes and flatten nested arrays
    options = options.collect do |x|
      x.is_a?(Hash) ? x.keys.sort.collect { |k| "#{k}=#{x[k]}" } : x
    end.flatten

    # add some flags we think are mandatory for the given operation
    extra.each { |f| options.unshift(f) unless options.include?(f) }
    options -= deny
  end

  # For internal use only
  def do_portupgrade(name, args, package_settings)
    cmd = args + [name]
    begin
      sync_package_settings(package_settings)
      if portupgrade(*cmd) =~ /\*\* No such /
        raise Puppet::ExecutionFailure, "Could not find package #{name}"
      end
    rescue
      revert_package_settings
      raise
    end
  end
  private :do_portupgrade

  # install new package (only if it's not installed).
  def install
    # we prefetched also not installed ports so @portorigin may be present
    name = @portorigin || resource[:name]
    do_portupgrade name, install_options, resource[:package_settings]
  end

  # reinstall already installed package with new options.
  def reinstall(options)
    if @portorigin
      do_portupgrade portorigin, reinstall_options, options
    else
      warning "Could not reinstall package '#{name}' which has no port origin."
    end
  end

  # upgrade already installed package.
  def update
    if properties[:ensure] == :absent
      install
    elsif @portorigin
      do_portupgrade portorigin, upgrade_options, resource[:package_settings]
    else
      warning "Could not upgrade package '#{name}' which has no port origin."
    end
  end

  # uninstall already installed package
  def uninstall
    cmd = uninstall_options + [pkgname]
    portuninstall(*cmd)
  end

  # If there are multiple packages, we only use the last one
  # rubocop: disable MethodLength, AbcSize, CyclomaticComplexity
  def latest
    # If there's no "latest" version, we just return a placeholder
    result = :latest
    oldversion = properties[:ensure]
    case portstatus
    when '>', '='
      result = oldversion
    when '<'
      raise Puppet::Error, "Could not match version info #{portinfo.inspect}." \
        unless (m = portinfo.match(/\((\w+) has (.+)\)/))
      source, newversion = m[1, 2]
      debug "Newer version in #{source}"
      result = newversion
    when '?'
      warning "The installed package '#{pkgname}' does not appear in the " \
              'ports database nor does its port directory exist.'
    when '!'
      warning "The installed package '#{pkgname}' does not appear in the " \
              'ports database, the port directory actually exists, but the ' \
              'latest version number cannot be obtained.'
    when '#'
      warning "The installed package '#{pkgname}' does not have an origin " \
              'recorded.'
    else
      warning "Invalid status flag #{portstatus.inspect} for package " \
              "'#{pkgname}' (returned by portversion command)."
    end
    result
  end
  # rubocop: enable MethodLength, AbcSize, CyclomaticComplexity

  def query
    # support names, portorigin, pkgname and portname
    (inst = self.class.instances([name]).last) ? inst.properties : nil
  end
end
# rubocop: enable BlockLength
