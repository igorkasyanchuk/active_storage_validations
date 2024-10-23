# frozen_string_literal: true

require 'active_model'
require 'active_support/concern'

require 'active_storage_validations/railtie'
require 'active_storage_validations/engine'
require 'active_storage_validations/attached_validator'
require 'active_storage_validations/content_type_validator'
require 'active_storage_validations/limit_validator'
require 'active_storage_validations/dimension_validator'
require 'active_storage_validations/aspect_ratio_validator'
require 'active_storage_validations/processable_image_validator'
require 'active_storage_validations/size_validator'
require 'active_storage_validations/total_size_validator'

require 'active_storage_validations/marcel_extensor'

ActiveSupport.on_load(:active_record) do
  send :include, ActiveStorageValidations
end
