# frozen_string_literal: true

class AspectRatio::Validator::OptimizedWithValidateAttached < ApplicationRecord
  has_one_attached :short_circuit_metadata_analysis_because_of_size_validaton
  validate_attached :short_circuit_metadata_analysis_because_of_size_validaton,
                    aspect_ratio: :square,
                    size: { less_than: 10.kilobytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_size_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_size_validaton,
                    aspect_ratio: :square,
                    size: { less_than: 10.kilobytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_total_size_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_total_size_validaton,
                    aspect_ratio: :square,
                    total_size: { less_than: 10.kilobytes }

  has_one_attached :short_circuit_metadata_analysis_because_of_content_type_validaton
  validate_attached :short_circuit_metadata_analysis_because_of_content_type_validaton,
                    aspect_ratio: :square,
                    content_type: :png,
                    size: { less_than: 10.megabytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_content_type_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_content_type_validaton,
                    aspect_ratio: :square,
                    content_type: :png,
                    size: { less_than: 10.megabytes }

  has_many_attached :short_circuit_metadata_many_analysis_because_of_limit_validaton
  validate_attached :short_circuit_metadata_many_analysis_because_of_limit_validaton,
                    aspect_ratio: :square,
                    limit: { min: 1, max: 2 },
                    size: { less_than: 10.megabytes }
end
