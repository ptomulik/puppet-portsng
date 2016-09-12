# rubocop: disable ClassAndModuleChildren, LineLength
begin
  Specinfra::Command::Freebsd::V9::Package.shell_check_pkgng
rescue NameError
  begin
    Specinfra::Command::Freebsd::V9
  rescue NameError
    class Specinfra::Command::Freebsd::V9 < Specinfra::Command::Freebsd::Base
    end
  end
  # Monkey-patch specinfra such that it supports freebsd-9 with pkgng stack.
  class Specinfra::Command::Freebsd::V9::Package < Specinfra::Command::Freebsd::Base::Package
    class << self
      def shell_check_pkgng
        'test `sysctl -n kern.osreldate` -ge 903000 && pkg -N >/dev/null 2>&1'
      end

      def shell_ifelse(cond, stmt_t, stmt_f)
        "if #{cond}; then #{stmt_t}; else #{stmt_f}; fi"
      end

      def check_is_installed(package, version = nil)
        if version
          shell_ifelse shell_check_pkgng,
                       "pkg query %v #{escape(package)} | grep -- #{escape(version)}",
                       "pkg_info -I #{escape(package)}-#{escape(version)}"
        else
          shell_ifelse shell_check_pkgng,
                       "pkg info -e #{escape(package)}",
                       "pkg_info -Ix #{escape(package)}"
        end
      end

      def install(package, _version = nil, option = '')
        shell_ifelse shell_check_pkgng,
                     "pkg install -y #{option} #{package}",
                     "pkg_add -r #{option} install #{package}"
      end

      def get_version(package, _options = nil)
        shell_ifelse shell_check_pkgng,
                     "pkg query %v #{escape(package)}",
                     "pkg_info -Ix #{escape(package)} | cut -f 1 -w | sed -n 's/^#{escape(package)}-//p'"
      end
    end
  end
end
# rubocop: enable ClassAndModuleChildren, LineLength
