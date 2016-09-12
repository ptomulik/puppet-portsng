require 'spec_helper_acceptance'

# rubocop: disable LineLength
describe 'portsng provider' do
  def package_setting(portname, optname)
    cmd = "make -C /usr/ports/#{portname} showconfig | awk -F '[=:]' '/#{optname}/ {print $2}'"
    shell(cmd).stdout.strip
  end

  portname = 'misc/ddate'

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

  context "package {'#{portname}': package_settings => {'USFORMAT' => false} }" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => present, package_settings => {'USFORMAT' => false} }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to be_installed }
    end
    describe 'package option USFORMAT' do
      it { expect(package_setting(portname, 'USFORMAT')).to eq 'off' }
    end
    describe 'package option KILLBOB' do
      it { expect(package_setting(portname, 'KILLBOB')).to eq 'on' }
    end
    describe 'package option PRAISEBOB' do
      it { expect(package_setting(portname, 'PRAISEBOB')).to eq 'off' }
    end
  end

  context "package {'#{portname}': package_settings => {'USFORMAT' => true}}" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => present, package_settings => {'USFORMAT' => true} }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to be_installed }
    end
    describe 'package option USFORMAT' do
      it { expect(package_setting(portname, 'USFORMAT')).to eq 'on' }
    end
    describe 'package option KILLBOB' do
      it { expect(package_setting(portname, 'KILLBOB')).to eq 'on' }
    end
    describe 'package option PRAISEBOB' do
      it { expect(package_setting(portname, 'PRAISEBOB')).to eq 'off' }
    end
  end
end
# rubocop: enable all
