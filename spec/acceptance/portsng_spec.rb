require 'spec_helper_acceptance'

describe 'portsng provider' do

  skip_tests = true
  case fact('osfamily')
  when 'FreeBSD'
    portname = 'textproc/jq'
    skip_tests = false
  end

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

  context "package {'#{portname}': package_settings => {'DOCS' => false} }" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => present, package_settings => {'DOCS' => false} }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to be_installed }
    end
  end

  context "package {'textproc/jq': package_settings => {'DOCS' => true}}" do
    it 'runs without an error' do
      pp = <<-PP
        Package{ provider => portsng }
        package{ '#{portname}': ensure => present, package_settings => {'DOCS' => true} }
      PP
      # Run it twice for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    describe package(portname) do
      it { is_expected.to be_installed }
    end
  end
end
