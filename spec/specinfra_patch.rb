module V9Patch
  def shell_check_pkgng
    'TMPDIR=/dev/null ASSUME_ALWAYS_YES=1 PACKAGESITE=file:///nonexist ' \
    'pkg info -x \'pkg(-devel)?$\' > /dev/null 2>&1'
  end
  module_function :shell_check_pkgng
end

FreeBSD = Specinfra::Command::Freebsd

si_v9_needs_patch = false
begin
  si_check_pkgng = Specinfra::Command::Freebsd::V9::Package.shell_check_pkgng
rescue NameError
  si_v9_needs_patch = true
else
  si_v9_needs_patch = (si_check_pkgng != V9Patch.shell_check_pkgng)
end

# rubocop: disable ClassAndModuleChildren, LineLength
if si_v9_needs_patch
  begin
    Specinfra::Command::Freebsd::V9
  rescue NameError
    class Specinfra::Command::Freebsd::V9 < Specinfra::Command::Freebsd::Base
    end
  end
  # Monkey-patch specinfra such that it supports freebsd-9 with pkgng stack.
  class Specinfra::Command::Freebsd::V9::Package < Specinfra::Command::Freebsd::Base::Package
    class << self
      def pkg_info_pattern(package)
        # package - may be also a portorigin (origin/portname)
        "^#{package.split('/', 2)[-1]}-[0-9][0-9a-zA-Z_\.,]*$"
      end

      def shell_check_pkgng
        V9Patch.shell_check_pkgng
      end

      def shell_ifelse(cond, stmt_t, stmt_f)
        "if #{cond}; then #{stmt_t}; else #{stmt_f}; fi"
      end

      def check_is_installed(package, version = nil)
        if version
          shell_ifelse(shell_check_pkgng,
                       "pkg query %v #{escape(package)} | grep -- #{escape(version)}",
                       "pkg_info -I #{escape(package)}-#{escape(version)}")
        else
          pattern = pkg_info_pattern(package)
          shell_ifelse(shell_check_pkgng,
                       "pkg info -e #{escape(package)}",
                       "pkg_info -Ix #{escape(pattern)}")
        end
      end

      def install(package, _version = nil, option = '')
        shell_ifelse(shell_check_pkgng,
                     "pkg install -y #{option} #{package}",
                     "pkg_add -r #{option} install #{package}")
      end

      def get_version(package, _options = nil)
        pattern = pkg_info_pattern(package)
        shell_ifelse(shell_check_pkgng,
                     "pkg query %v #{escape(package)}",
                     "pkg_info -Ix #{escape(pattern)} | cut -f 1 -w | sed -n 's/^#{escape(package)}-//p'")
      end
    end
  end
end

si_base_needs_patch = (Specinfra::Command::Freebsd::Base::Package.install('foo') =~ /pkg_add/)
if si_base_needs_patch
  class Specinfra::Command::Freebsd::Base::Package
    class << self
      def check_is_installed(package, version = nil)
        if version
          "pkg query %v #{escape(package)} | grep -- #{escape(version)}"
        else
          "pkg info -e #{escape(package)}"
        end
      end

      def install(package, _version = nil, option = '')
        "pkg install -y #{option} #{package}"
      end

      def get_version(package, _options = nil)
        "pkg query %v #{escape(package)}"
      end
    end
  end
end
# rubocop: enable ClassAndModuleChildren, LineLength
