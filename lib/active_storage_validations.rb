require 'active_storage_validations/railtie'
require 'active_storage_validations/engine'
require 'active_storage_validations/attached_validator'
require 'active_storage_validations/content_type_validator'
require 'active_storage_validations/size_validator'




ActiveRecord::Base.send :include, ActiveStorageValidations
