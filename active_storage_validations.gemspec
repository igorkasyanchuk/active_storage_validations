# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'active_storage_validations/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'active_storage_validations'
  s.version     = ActiveStorageValidations::VERSION
  s.authors     = [ 'Igor Kasyanchuk' ]
  s.email       = [ 'igorkasyanchuk@gmail.com' ]
  s.homepage    = 'https://github.com/igorkasyanchuk/active_storage_validations'
  s.summary     = 'Validations for Active Storage'
  s.description = 'Validations for Active Storage (presence)'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 2.5.0' # We support Rails >= 6.1.4

  %w[activejob activemodel activestorage activesupport].each { |rails_subcomponent| s.add_dependency rails_subcomponent, '>= 6.1.4' }
  s.add_dependency 'marcel', ">= 1.0.3" # necessary for mime type spoofing features, required for Rails >= 6.1.4 anyway

  s.add_development_dependency 'combustion', "~> 1.3"
  s.add_development_dependency 'mini_magick', ">= 4.9.5"
  s.add_development_dependency 'minitest-focus', '~> 1.4'
  s.add_development_dependency 'minitest-mock_expectations', '~> 1.2', '>= 1.2.0'
  s.add_development_dependency 'minitest-stub_any_instance', '~> 1.0', '>= 1.0.3'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'ruby-vips', ">= 2.1.0"
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3', '>= 2.5' # To support Ruby 3.4, we need to use sqlite3 >= 2.5
  s.add_development_dependency 'webmock', ">= 3"
end
