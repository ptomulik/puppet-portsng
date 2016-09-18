if RUBY_VERSION >= '1.9'
  require 'coveralls'
  Coveralls.wear! do
    add_filter 'spec/'
    add_filter 'lib/puppet/provider/package.rb'
    add_filter 'lib/puppet/provider/package/openbsd.rb'
    add_filter 'lib/puppet/provider/package/freebsd.rb'
  end
end

require 'puppetlabs_spec_helper/module_spec_helper'
module_path = RSpec.configuration.module_path
$LOAD_PATH.unshift File.join(module_path, 'backports/lib')
$LOAD_PATH.unshift File.join(module_path, 'package_resource/lib')
$LOAD_PATH.unshift File.join(module_path, 'portsutil/lib')
$LOAD_PATH.unshift File.join(module_path, 'vash/lib')
