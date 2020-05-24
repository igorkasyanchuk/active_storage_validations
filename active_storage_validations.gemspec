# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'active_storage_validations/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'active_storage_validations'
  s.version     = ActiveStorageValidations::VERSION
  s.authors     = ['Igor Kasyanchuk']
  s.email       = ['igorkasyanchuk@gmail.com']
  s.homepage    = 'https://github.com/igorkasyanchuk/active_storage_validations'
  s.summary     = 'Validations for Active Storage'
  s.description = 'Validations for Active Storage (presence)'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'rails', ">= 5.2.0"
  s.add_development_dependency 'mini_magick', ">= 4.9.5"
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rubocop'
end
