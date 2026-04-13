# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_optionable"

require_relative "aspect_ratio_validator"
require_relative "attached_validator"
require_relative "content_type_validator"
require_relative "dimension_validator"
require_relative "duration_validator"
require_relative "limit_validator"
require_relative "pages_validator"
require_relative "processable_file_validator"
require_relative "size_validator"
require_relative "total_size_validator"

module ActiveStorageValidations
  class AttachmentValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVLoggable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[
      aspect_ratio
      attached
      content_type
      dimension
      duration
      limit
      pages
      processable_file
      size
      total_size
    ].freeze

    VALIDATORS = {
      aspect_ratio: ActiveStorageValidations::AspectRatioValidator,
      attached: ActiveStorageValidations::AttachedValidator,
      content_type: ActiveStorageValidations::ContentTypeValidator,
      dimension: ActiveStorageValidations::DimensionValidator,
      duration: ActiveStorageValidations::DurationValidator,
      limit: ActiveStorageValidations::LimitValidator,
      pages: ActiveStorageValidations::PagesValidator,
      processable_file: ActiveStorageValidations::ProcessableFileValidator,
      size: ActiveStorageValidations::SizeValidator,
      total_size: ActiveStorageValidations::TotalSizeValidator
    }.freeze

    def check_validity!
      ensure_at_least_one_validator_option
      ensure_size_validator_present_if_heavyweight_validator_requested
    end

    def validate_each(record, attribute, _value)
      return unless attachments_present?(record, attribute)

      lightweight_validators, heavyweight_validators = partition_validators

      lightweight_valid = run_validator_group(record, attribute, lightweight_validators)

      unless lightweight_valid
        log_heavyweight_validations_skipped(record, attribute, heavyweight_validators) if heavyweight_validators.any?
        return
      end

      run_validator_group(record, attribute, heavyweight_validators)
    end

    private

    def partition_validators
      return [ [], [] ] if VALIDATORS.empty?

      VALIDATORS.each_with_object([ [], [] ]) do |(key, klass), (light, heavy)|
        opts = options[key]
        next unless opts

        normalized = normalize_validator_options(opts)

        klass.validation_steps(normalized).each do |step_opts|
          if klass.heavyweight?(step_opts)
            heavy << [ key, klass, step_opts ]
          else
            light << [ key, klass, step_opts ]
          end
        end
      end
    end

    def run_validator_group(record, attribute, validators)
      validators.all? do |key, klass, step_opts|
        run_validator(
          klass,
          record,
          attribute,
          step_opts
            .merge(shared_validator_options)
            .merge(_asv_orchestrated: true)
        )
      end
    end

    def run_validator(validator_class, record, attribute, validator_options)
      validator = validator_class.new(
        attributes: [ attribute ],
        **validator_options
      )

      before_count = record.errors.count
      validator.validate(record)
      record.errors.count == before_count
    end

    def normalize_validator_options(value)
      case value
      when Hash then value
      when Array, Set then { in: value }
      when TrueClass then {} # means “enabled with defaults”
      else
        { with: value } # Symbol, String, Numeric, etc.
      end
    end

    def shared_validator_options
      options.slice(*ActiveStorageValidations::RAILS_VALIDATOR_OPTIONS)
    end

    def log_heavyweight_validations_skipped(record, attribute, heavyweight_validators)
      logger.debug(
        event: "asv.heavyweight_validations_skipped",
        model: record.class.name,
        attribute: attribute,
        skipped_heavyweight_validators: heavyweight_validators.map(&:first)
      )
    end

    def ensure_at_least_one_validator_option
      return if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }

      raise ArgumentError, error_message_at_least_one_validator_option
    end

    def error_message_at_least_one_validator_option
      "You must pass validator options (:size, :dimension, ...) to the `validate_attached` method"
    end

    def ensure_size_validator_present_if_heavyweight_validator_requested
      _lightweight_validators, heavyweight_validators = partition_validators
      heavyweight_validators_sym = heavyweight_validators.map(&:first)

      return unless heavyweight_validations_requested?(heavyweight_validators_sym)

      unless size_validator_present? || total_size_validator_present?
        raise ArgumentError, error_message_size_validator_present_if_heavyweight_validator_requested(heavyweight_validators_sym)
      end
    end

    def heavyweight_validations_requested?(heavyweight_validators)
      heavyweight_validators.any? { |key| options.key?(key) }
    end

    def error_message_size_validator_present_if_heavyweight_validator_requested(heavyweight_validators)
      "Using `validate_attached` with heavyweight validators (#{heavyweight_validators.join(', ')}) requires a :size or :total_size option."
    end

    def size_validator_present?
      options.key?(:size)
    end

    def total_size_validator_present?
      options.key?(:total_size)
    end
  end
end
