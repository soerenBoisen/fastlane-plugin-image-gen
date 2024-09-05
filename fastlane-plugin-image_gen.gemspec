lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/image_gen/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-image_gen'
  spec.version       = Fastlane::ImageGen::VERSION
  spec.author        = 'Søren Boisen'
  spec.email         = 'soeren.boisen@facilitynet.dk'

  spec.summary       = 'Generate images for iOS and Android from a master SVG'
  # spec.homepage      = "https://github.com/<GITHUB_USERNAME>/fastlane-plugin-image_gen"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.6'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
  spec.add_dependency('nokogiri', '~> 1.16.4')
end
