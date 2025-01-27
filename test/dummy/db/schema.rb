# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :active_storage_attachments, force: :cascade do |t|
    t.string :name, null: false
    t.string :record_type, null: false
    t.integer :record_id, null: false
    t.integer :blob_id, null: false
    t.datetime :created_at, null: false
    t.index %i[blob_id], name: :index_active_storage_attachments_on_blob_id
    t.index %i[record_type record_id name blob_id], name: :index_active_storage_attachments_uniqueness, unique: true
  end

  create_table :active_storage_blobs, force: :cascade do |t|
    t.string :key, null: false
    t.string :filename, null: false
    t.string :content_type
    t.text :metadata
    t.bigint :byte_size, null: false
    t.string :checksum, null: false
    t.datetime :created_at, null: false
    t.index %i[key], name: :index_active_storage_blobs_on_key, unique: true

    t.string :service_name, null: false
  end

  create_table :active_storage_variant_records, force: :cascade do |t|
    t.bigint :blob_id, null: false
    t.string :variation_digest, null: false
    t.index %i[blob_id variation_digest], name: :index_active_storage_variant_records_uniqueness, unique: true
  end

  # Gem specific test tables

  create_table :active_storage_validations_checks, force: :cascade do |t|
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  %i(
    aspect_ratio
    attached
    content_type
    dimension
    duration
    limit
    processable_file
    size
    total_size
  ).each do |validator|
    create_table :"#{validator}_matchers", force: :cascade do |t|
      t.string :title
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    %w(invalid_check no_check).each do |invalid_case|
      create_table :"#{validator}_validator_check_validity_#{invalid_case.pluralize}", force: :cascade do |t|
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
      end
    end

    if %i(content_type duration size total_size).include? validator
      create_table :"#{validator}_validator_check_validity_several_checks", force: :cascade do |t|
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
      end
    end

    create_table :"#{validator}_validator_checks", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    %i(allow_nil allow_blank if on strict unless message).each do |option|
      create_table :"#{validator}_validator_with_#{option.to_s.pluralize}", force: :cascade do |t|
        t.string :title if option == :if
        t.integer :rating if option == :unless
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
      end
    end
  end

  %i(
    aspect_ratio
    content_type
    dimension
    processable_file
  ).each do |validator|
    create_table :"#{validator}_validator_using_attachables", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end

  %i(
    aspect_ratio
    content_type
    dimension
    duration
    processable_file
  ).each do |validator|
    create_table :"#{validator}_validator_is_performance_optimizeds", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end

  %w(proc_option invalid_named_argument invalid_is_xy_argument).each do |invalid_case|
    create_table :"aspect_ratio_validator_check_validity_#{invalid_case.pluralize}", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end

  %w(proc_option invalid_content_type_with invalid_content_type_in invalid_content_type_jpg valid_ct_ole_storage invalid_extension regex_option).each do |invalid_case|
    create_table :"content_type_validator_check_validity_#{invalid_case.pluralize}", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end

  %w(proc_option invalid_argument max_higher_than_min).each do |invalid_case|
    create_table :"limit_validator_check_validity_#{invalid_case.pluralize}", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end

  %w(min min_proc max max_proc range range_proc).each do |check|
    create_table :"limit_validator_check_#{check.pluralize}", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end

  create_table :total_size_validator_check_validity_has_many_attached_onlies, force: :cascade do |t|
    t.datetime :created_at, precision: 6, null: false
    t.datetime :updated_at, precision: 6, null: false
  end

  create_table :documents, force: :cascade do |t|
    t.datetime :created_at, precision: 6, null: false
    t.datetime :updated_at, precision: 6, null: false
  end

  create_table :integration_matchers, force: :cascade do |t|
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  %w(
    based_on_a_file_property
    performance
    zero_byte_image
  ).each do |integration_test|
    create_table :"integration_validator_#{integration_test.pluralize}", force: :cascade do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end

  create_table :limit_attachments, force: :cascade do |t|
    t.string :name
  end

  create_table :only_images, force: :cascade do |t|
    t.datetime :created_at, precision: 6, null: false
    t.datetime :updated_at, precision: 6, null: false
  end

  create_table :content_type_spoof_detectors, force: :cascade do |t|
    t.datetime :created_at, precision: 6, null: false
    t.datetime :updated_at, precision: 6, null: false
  end

  create_table :metadata, force: :cascade do |t|
    t.datetime :created_at, precision: 6, null: false
    t.datetime :updated_at, precision: 6, null: false
  end

  create_table :projects, force: :cascade do |t|
    t.string :title
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  create_table :ratio_models, force: :cascade do |t|
    t.string :name
    t.datetime :created_at, precision: 6, null: false
    t.datetime :updated_at, precision: 6, null: false
  end

  create_table :users, force: :cascade do |t|
    t.string :name
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end
end
