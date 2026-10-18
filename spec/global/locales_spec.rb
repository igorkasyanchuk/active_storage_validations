# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/DescribeClass -- locale YAML contract, not a Ruby class
RSpec.describe "I18n locale files" do
  subject(:english_catalog) { locale_catalog.fetch("en") }

  let(:locale_root) { File.expand_path("../../config/locales", __dir__) }
  let(:locale_catalog) do
    Dir[File.join(locale_root, "*.yml")].each_with_object({}) do |path, catalog|
      locale = File.basename(path, ".yml")
      catalog[locale] = flatten_locale(YAML.load_file(path).fetch(locale))
    end
  end

  # CLDR plural forms beyond English one / other. Every pluralized key carries
  # them in these locales, so apps using rails-i18n pluralization rules get
  # "2 секунды" / "5 секунд" instead of falling back to other.
  let(:extra_plural_forms) do
    {
      "pl" => %w[few many],
      "ru" => %w[few many],
      "uk" => %w[few many]
    }
  end

  describe "keys" do
    it "keeps every locale in sync with en.yml" do
      locale_catalog.each do |locale, catalog|
        next if locale == "en"

        expected_keys = english_catalog.keys + extra_plural_keys(locale)

        expect(catalog.keys).to match_array(expected_keys), <<~MESSAGE
          #{locale}.yml keys do not match en.yml (plus #{extra_plural_forms.fetch(locale, []).join(" / ").presence || "no"} plural forms)
          missing: #{(expected_keys - catalog.keys).join(", ")}
          extra: #{(catalog.keys - expected_keys).join(", ")}
        MESSAGE
      end
    end
  end

  describe "interpolation placeholders" do
    it "includes at least the English placeholders" do
      english_placeholders = english_catalog.transform_values { |value| placeholders_in(value) }

      locale_catalog.each do |locale, catalog|
        next if locale == "en"

        english_placeholders.each do |key, expected|
          actual = placeholders_in(catalog[key])
          missing = expected - actual

          expect(missing).to be_empty, <<~MESSAGE
            #{locale}.yml #{key} is missing interpolation placeholders: #{missing.join(", ")}
            en: #{expected.join(", ")}
            #{locale}: #{actual.join(", ")}
          MESSAGE
        end
      end
    end
  end

  describe "extra plural forms" do
    it "keep the English placeholders of the other form" do
      english_placeholders = english_catalog.transform_values { |value| placeholders_in(value) }

      extra_plural_forms.each do |locale, forms|
        catalog = locale_catalog.fetch(locale)

        extra_plural_keys(locale).each do |key|
          expected = english_placeholders.fetch(key.sub(/\.(#{forms.join("|")})\z/, ".other"))
          missing = expected - placeholders_in(catalog[key])

          expect(missing).to be_empty, "#{locale}.yml #{key} is missing interpolation placeholders: #{missing.join(", ")}"
        end
      end
    end
  end

  private

  def extra_plural_keys(locale)
    forms = extra_plural_forms.fetch(locale, [])

    english_catalog.keys.grep(/\.other\z/).flat_map do |key|
      forms.map { |form| key.sub(/\.other\z/, ".#{form}") }
    end
  end

  def flatten_locale(value, prefix = nil)
    case value
    when Hash
      value.each_with_object({}) do |(key, nested), catalog|
        catalog.merge!(flatten_locale(nested, [ prefix, key ].compact.join(".")))
      end
    else
      { prefix => value }
    end
  end

  def placeholders_in(value)
    Array(value).flat_map { |string| string.to_s.scan(/%\{(\w+)\}/).flatten }.uniq.sort
  end
end
# rubocop:enable RSpec/DescribeClass
