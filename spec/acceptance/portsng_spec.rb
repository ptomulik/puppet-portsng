require 'spec_helper_acceptance'

# rubocop: disable LineLength
describe 'portsng provider' do
  def package_settings(portname)
    out = shell("make showconfig -C /usr/ports/#{portname}").stdout
    arr = out.lines.select { |x| x =~ /^\s*[_a-zA-Z][_a-zA-Z0-9]+\s*=.+$/ }
    arr = arr.map { |x| x.strip.split('=', 2).map { |y| y.split(/[^\w]/)[0] } }
    Hash[arr]
  end

  def package_setting(portname, optname)
    package_settings(portname)[optname]
  end

  portname = 'net/datapipe'
  optnname = 'REUSEADDR'

  context "package {'#{portname}': ensure => absent}" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => absent }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to_not be_installed }
    end
  end

  context "package {'#{portname}': ensure => present}" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => present }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to be_installed }
    end
  end

  context "package {'#{portname}': package_settings => {'#{optnname}' => false} }" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => present, package_settings => {'#{optnname}' => false} }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to be_installed }
    end
    describe "package option #{optnname}" do
      it { expect(package_setting(portname, optnname)).to eq 'off' }
    end
  end

  context "package {'#{portname}': package_settings => {'#{optnname}' => true}}" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => present, package_settings => {'#{optnname}' => true} }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to be_installed }
    end
    describe "package option #{optnname}" do
      it { expect(package_setting(portname, optnname)).to eq 'on' }
    end
  end

  context "package {'#{portname}': ensure => absent} (uninstalling)" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => absent }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to_not be_installed }
    end
  end
end
# rubocop: enable all
