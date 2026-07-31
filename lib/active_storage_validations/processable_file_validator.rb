# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class ProcessableFileValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVSymbolizable

    ERROR_TYPES = %i[
      file_not_processable
    ].freeze
    METADATA_KEYS = %i[].freeze

    # Content types whose libvips loaders are marked untrusted / unfuzzed
    # (VIPS_OPERATION_UNTRUSTED). After Rails calls `Vips.block_untrusted(true)`,
    # analysis of these types returns no width/height (empty metadata here),
    # which is not the same as a corrupt / unprocessable file.
    #
    # Matches the formats called out in the Active Storage security release
    # changelogs (7.2.3.2 / 8.0.5.1 / 8.1.3.1):
    # https://github.com/rails/rails/blob/v8.1.3.1/activestorage/CHANGELOG.md
    # https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm
    VIPS_UNTRUSTED_CONTENT_TYPES = %w[
      image/bmp
      image/vnd.microsoft.icon
      image/vnd.adobe.photoshop
      image/svg+xml
      image/jxl
      image/jp2
      image/x-portable-anymap
      image/x-portable-bitmap
      image/x-portable-graymap
      image/x-portable-pixmap
    ].freeze

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute, METADATA_KEYS)
    end

    private

    def is_valid?(record, attribute, attachable, metadata)
      return if metadata.present?
      return if vips_unanalyzable_by_policy?(attachable)

      errors_options = initialize_error_options(options, attachable)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
    end

    def vips_unanalyzable_by_policy?(attachable)
      image_processor == :vips &&
        self.class.vips_untrusted_operations_blocked? &&
        VIPS_UNTRUSTED_CONTENT_TYPES.include?(attachable_content_type(attachable))
    end

    class << self
      # Detect whether libvips is currently blocking untrusted operations.
      # There is no public getter for `Vips.block_untrusted`, so we probe whether
      # an untrusted loader (svgload) is available via `vips_foreign_find_load`.
      def vips_untrusted_operations_blocked?
        return @vips_untrusted_operations_blocked if defined?(@vips_untrusted_operations_blocked)

        @vips_untrusted_operations_blocked = detect_vips_untrusted_operations_blocked?
      end

      def reset_vips_untrusted_operations_blocked_cache!
        remove_instance_variable(:@vips_untrusted_operations_blocked) if defined?(@vips_untrusted_operations_blocked)
      end

      private

      def detect_vips_untrusted_operations_blocked?
        require "vips"
        require "tempfile"

        Tempfile.create([ "asv_vips_untrusted_probe", ".svg" ]) do |file|
          file.write('<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>')
          file.flush
          ::Vips.vips_foreign_find_load(file.path).nil?
        end
      rescue LoadError, StandardError
        false
      end
    end
  end
end
