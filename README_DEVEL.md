# ptomulik-portsng

## Before anything

```code
bundle install --path vendor
```

If you don't plan running acceptance tests, then you may

```code
bundle install --path vendor --without 'acceptance_tests'
```

## Running unit tests

```console
bundle exec rake spec
```

## Running acceptance tests

```console
bundle exec rake beaker
```

See also the [the list of beaker environment variables](https://github.com/puppetlabs/beaker-rspec/blob/master/README.md#supported-env-variables).

In addition, we support the following variables

- ``BEAKER_puppet`` - name of the puppet package to be installed on hosts,
  for example ``BEAKER_puppet="puppet37"``


To run on different platforms, use

```console
bundle exec rake beaker:<platform-identifier>
```

for example

```console
bundle exec rake beaker:freebsd-12.0-amd64
```

Alternativelly, you may also set the ``BEAKER_set`` variable, for example

```console
BEAKER_set=freebsd-12.0-amd64 bundle exec rake beaker
```
