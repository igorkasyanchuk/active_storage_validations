# frozen_string_literal: true

class ContentType::Validator::OptimizedWithValidateAttached < ApplicationRecord
  has_one_attached :short_circuit_metadata_analysis_because_of_size_validaton
  validate_attached :short_circuit_metadata_analysis_because_of_size_validaton,
                    content_type: { with: :png, spoofing_protection: true },
                    size: { less_than: 10.kilobytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_size_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_size_validaton,
                    content_type: { with: :png, spoofing_protection: true },
                    size: { less_than: 10.kilobytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_total_size_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_total_size_validaton,
                    content_type: { with: :png, spoofing_protection: true },
                    total_size: { less_than: 10.kilobytes }

  has_one_attached :short_circuit_metadata_analysis_because_of_content_type_validaton
  validate_attached :short_circuit_metadata_analysis_because_of_content_type_validaton,
                    content_type: { with: :png, spoofing_protection: true },
                    size: { less_than: 10.megabytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_content_type_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_content_type_validaton,
                    content_type: { with: :png, spoofing_protection: true },
                    size: { less_than: 10.megabytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_limit_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_limit_validaton,
                    content_type: { with: :png, spoofing_protection: true },
                    limit: { min: 1, max: 2 },
                    size: { less_than: 10.megabytes }
end
