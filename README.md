# ptomulik-portsng

[![Build Status](https://travis-ci.org/ptomulik/puppet-portsng.png?branch=master)](https://travis-ci.org/ptomulik/puppet-portsng)
[![Coverage Status](https://coveralls.io/repos/ptomulik/puppet-portsng/badge.png?branch=master)](https://coveralls.io/r/ptomulik/puppet-portsng?branch=master)

####<a id="table-of-contents"></a>Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What portsng affects](#what-portsng-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with portsng](#beginning-with-portsng)
4. [Limitations](#limitations)
5. [Development](#development)

##<a id="overview"></a> Overview

This is a __ports__ provider for package resource.

##<a id="module-description"></a>Module Description

The module re-implements puppet's __ports__ provider adding some new features
to it and fixing several existing issues. The new features include:

  * *install_options* - extra CLI flags passed to *portupgrade* when
    installing, reinstalling and upgrading packages,
  * *uninstall_options* - extra CLI flags passed to *pkg_deinstall* (old
    [pkg](http://www.freebsd.org/doc/handbook/packages-using.html) toolstack)
    or *pkg delete*
    ([pkgng](http://www.freebsd.org/doc/handbook/pkgng-intro.html)) when
    uninstalling packages,
  * *package_settings* - configuration options for package,
  * works wit both the old
    [pkg](http://www.freebsd.org/doc/handbook/packages-using.html) and new
    [pkgng](http://www.freebsd.org/doc/handbook/pkgng-intro.html) package
    databases,
  * *upgradeable* (tested, the original puppet provider declared that it's
    upgradeable, but it never worked for me),
  * *portorigins* (instead of *portnames*) are used internally to identify
    package instances,
  * [portversion](http://www.freebsd.org/cgi/man.cgi?query=portversion&manpath=ports&sektion=1)
    is used to find installed packages (instead of *pkg_info*),
  * [make search](http://www.freebsd.org/cgi/man.cgi?query=ports&sektion=7) is
    used to find (not-installed) ports listed in puppet manifests,
  * several issues resolved,

The *package_settings* is simply an `{OPTION => value}` hash, with boolean
values. The *portsng* provider ensures that package is compiled with prescribed
*package_settings*. Normally you would set these options with *make config*
command using ncurses-based frontend. Here, you can define *package_settings*
in your puppet manifest. If a package is already installed and you change its
*package_settings* in manifest file, the package gets rebuilt with new options
and reinstalled.

Instead of *portnames*, *portorigins* are used to identify *portsng* instances
(see [FreeBSD ports collection and it's
terminology](#freebsd-ports-collection-and-its-terminology)). This copes with
several problems caused by portnames' ambiguity (see [FreeBSD ports collection
and ambiguity of
portnames](#freebsd-ports-collection-and-ambiguity-of-portnames)). You can now
install and mainain ports that have common *portname* (but different
portorigins). Examples of such packages include *mysql-client* or *ruby* (see
below).

The [portversion](http://www.freebsd.org/cgi/man.cgi?query=portversion&manpath=ports&sektion=1)
utility is used to find installed ports. It's better than using
[pkg_info](http://www.freebsd.org/cgi/man.cgi?query=pkg_info&sektion=1) for
several reasons. First, it is said to be faster, because it uses compiled
version of ports INDEX file. Second, it works with both - the old
[pkg](http://www.freebsd.org/doc/handbook/packages-using.html) database and the
new [pkgng](http://www.freebsd.org/doc/handbook/pkgng-intro.html) database,
providing seamless interface to any of them. Third, it provides package names
and their "out-of-date" statuses in a single call, so we don't need to
separatelly check out-of-date status for installed packages. This version of
*portsng* works with old *pkg* database as well as with *pkgng*, using
*portversion*.

####<a id="freebsd-ports-collection-and-its-terminology"></a>FreeBSD ports collection and its terminology

We use the following terminology when referring ports/packages:

  * a string in form `'apache22'` or `'ruby'` is referred to as *portname*
  * a string in form `'apache22-2.2.25'` or `'ruby-1.8.7.371,1'` is referred to
    as a *pkgname*
  * a string in form `'www/apache22'` or `'lang/ruby18'` is referred to as a
    port *origin* or *portorigin*

See [http://www.freebsd.org/doc/en/books/porters-handbook/makefile-naming.html](http://www.freebsd.org/doc/en/books/porters-handbook/makefile-naming.html)

Port *origins* are used as primary identifiers for *portsng* instances. It's recommended to use *portorigins* instead of *portnames* as package names in manifest files.

####<a id="freebsd-ports-collection-and-ambiguity-of-portnames"></a>FreeBSD ports collection and ambiguity of portnames

Using *portnames* (e.g. `apache22`) as package names in manifests is allowed.
The *portname*s, however, are ambiguous, meaning that port search may find
multiple ports matching the given *portname*. For example `'mysql-client'`
package has three ports at the time of this writing  (2013-11-30):
`mysql-client-5.1.71`, `mysql-client-5.5.33`, and `mysql-client-5.6.13` with
origins `databases/mysql51-client`, `databases/mysql55-client` and
`databases/mysql56-client` respectively. If none of these ports are installed
and you use this ambiguous *portname* in your manifest, you'll se the following
warning:

```console
Warning: Puppet::Type::Package::ProviderPorts: Found 3 ports named 'mysql-client': 'databases/mysql51-client', 'databases/mysql55-client', 'databases/mysql56-client'. Only 'databases/mysql56-client' will be ensured.
```

##<a id="setup"></a>Setup

###<a id="what-portsng-affects"></a>What portsng affects

* installs, upgrades, reinstalls and uninstalls packages,
* modifies FreeBSD ports options' files `/var/db/ports/*/options.local`,

###<a id="setup-requirements"></a>Setup Requirements

You may need to enable __pluginsync__ in your `puppet.conf`.

###<a id="beginning-with-portsng"></a>Beginning with portsng

Its usage is essentially same as for the original *ports* provider. Just select
*portsng* as the package provider

```puppet
Package { provider => portsng }
```

Below I just put some examples specific to new features of *portsng*.

####<a id="example-1---using-package_settings"></a>Example 1 - using *package_settings*

Ensure that www/apache22 is installed with SUEXEC:

```puppet
package { 'www/apache22': 
  package_settings => {'SUEXEC' => true}
}
```

####<a id="example-2---using-uninstall_options-to-cope-with-dependency-problems"></a> Example 2 - using *uninstall_options* to cope with dependency problems

Sometimes freebsd package manager refuses to uninstall a package due to
dependency problems that would appear after deinstallation. In such situations
we may use the `uninstall_options` to instruct the provider to uninstall also
all packages that depend on the package being uninstalled. When using ports
with old *pkg* package manager one would write in its manifest:

```puppet
package { 'www/apache22':
  ensure => absent,
  uninstall_options => ['-r'] 
}
```

For *pkgng* one has to write:

```puppet
package { 'www/apache22':
  ensure => absent,
  uninstall_options => ['-R','-y'] 
}
```

####<a id="example-3---using-install_options"></a>Example 3 - using *install_options*

The new *portsng* provider implements *install_options* feature. The flags
provided via *install_options* are passed to `portupgrade` command when
installing, reinstalling or upgrading packages. With no *install_options*
provided, sensible defaults are selected by *portsng* provider.

Let's say we want to install precompiled package, if available (`-P` flag).
Write the following manifest:

```puppet
package { 'www/apache22':
  ensure => present,
  install_options => ['-P', '-M', {'BATCH' => 'yes'}]
}
```

Now, if we run puppet, we'll see the command:

```console
~ # puppet agent -t --debug --trace
...
Debug: Executing '/usr/local/sbin/portupgrade -N -P -M BATCH=yes www/apache22'
...
```

Note, that the *portsng* provider adds some flags by its own (`-N` in the above
example). What is added/removed is preciselly stated in provider's generated
documentation.

##<a id="limitations"></a>Limitations

* If there are several ports installed with same *portname* - for example
  `docbook` - then `puppet resource package docbook` will list only one of
  them (the last one from `portversion`s list - usually the most recent). It is
  so, because `portsng` uses *portorigins* to identify its instances (as `name`
  paramateter). None of the existing `instances` is identified by `puppet` as
  an instance of `docbook` and `puppet` falls back to use provider's `query`
  method. But `query` handles only one package per name (in this case the last
  one from *portversion*'s list if chosen). This is an issue, which will not
  probably be fixed, so you're encouraged to use *portorigins*.
* Currently there is no system tests for the new *portsng* provider. This is,
  because there are no FreeBSD prefab images provided by `rspec-system` yet. I
  hope this changes in not so far future, see status of the [request for freebsd
  prefab images](https://github.com/puppetlabs/rspec-system/issues/52).


##<a id="development"></a>Development
The project is held at github:
* [https://github.com/ptomulik/puppet-portsng](https://github.com/ptomulik/puppet-portsng)
Issue reports, patches, pull requests are welcome!
