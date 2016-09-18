# rubocop: disable ClassAndModuleChildren
module FreeBSD::Pkg
  include Beaker::CommandFactory

  def shell_check_pkgng
    'TMPDIR=/dev/null ASSUME_ALWAYS_YES=1 PACKAGESITE=file:///nonexist ' \
    'pkg info -x "pkg(-devel)?\\$" > /dev/null 2>&1'
  end

  def shell_ifelse(cond, stmt_t, stmt_f)
    "if #{cond}; then #{stmt_t}; else #{stmt_f}; fi"
  end

  def install_package(package, cmdline_args = nil, opts = {})
    cmd = shell_ifelse shell_check_pkgng,
                       "pkg install #{cmdline_args || '-y'} #{package}",
                       "pkg_add #{cmdline_args || '-r'} #{package}"
    execute("/bin/sh -c '#{cmd}'", opts) { |result| result }
  end

  def check_for_package(package, opts = {})
    cmd = shell_ifelse shell_check_pkgng,
                       "pkg info #{package}",
                       "pkg_info -Iqx #{package} 2> /dev/null || true"
    execute("/bin/sh -c '#{cmd}'", opts) { |result| result }
  end
end
# rubocop: enable ClassAndModuleChildren
