# Active Storage Validations

If you are using `active_storage` gem and you want to add simple validations for it, like presence or content_type you need to write a custom valiation method.

This gems doing it for you. Just use `attached: true` or `content_type: 'image/png'` validation.

[![Build Status](https://travis-ci.org/igorkasyanchuk/active_storage_validations.svg?branch=master)](https://travis-ci.org/igorkasyanchuk/active_storage_validations)

## What it can do

* validates if file(s) attached
* validates content type
* validates size of files
* validates dimension of images/videos
* validates number of uploaded files (min/max required)
* custom error messages

## Usage

For example you have a model like this and you want to add validation.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos

  validates :name, presence: true

  validates :avatar, attached: true, content_type: 'image/png',
                                     dimension: { width: 200, height: 200 }
  validates :photos, attached: true, content_type: ['image/png', 'image/jpg', 'image/jpeg'],
                                     dimension: { width: { min: 800, max: 2400 },
                                                  height: { min: 600, max: 1800 }, message: 'is not given between dimension' }
end
```

or

```ruby
class Project < ApplicationRecord
  has_one_attached :preview
  has_one_attached :attachment
  has_many_attached :documents

  validates :title, presence: true

  validates :preview, attached: true, size: { less_than: 100.megabytes , message: 'is not given between size' }
  validates :attachment, attached: true, content_type: { in: 'application/pdf', message: 'is not a PDF' }
  validates :documents, limit: { min: 1, max: 3 }
end
```

### More examples

- Dimension validation with `width`, `height` and `in`.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos

  validates :avatar, dimension: { width: { in: 80..100 }, message: 'is not given between dimension' }
  validates :photos, dimension: { height: { in: 600..1800 } }
end
```

- Dimension validation with `min` and `max` range for width and height.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos

  validates :avatar, dimension: { min: 200..100 }
  # Equivalent to:
  # validates :avatar, dimension: { width: { min: 200 }, height: { min: 100  } }
  validates :photos, dimension: { min: 200..100, max: 400..200 }
  # Equivalent to:
  # validates :avatar, dimension: { width: { min: 200, max: 400 }, height: { min: 100, max: 200  } }
end
```

## Internationalization (I18n)

Active Storage Validations use I18n for errors messages. For this add there keys in your translation file:

```yml
en:
  errors:
    messages:
      content_type_invalid: "has an invalid content type"
      file_size_out_of_range: "size %{file_size} is not between required range"
      limit_out_of_range: "total number is out of range"
      dimension_min_inclusion: "must be greater than or equal to %{width} x %{height} pixel."
      dimension_max_inclusion: "must be less than or equal to %{width} x %{height} pixel."
      dimension_width_inclusion: "width is not included between %{min} and %{max} pixel."
      dimension_height_inclusion: "height is not included between %{min} and %{max} pixel."
      dimension_width_greater_than_or_equal_to: "width must be greater than or equal to %{length} pixel."
      dimension_height_greater_than_or_equal_to: "height must be greater than or equal to %{length} pixel."
      dimension_width_less_than_or_equal_to: "width must be less than or equal to %{length} pixel."
      dimension_height_less_than_or_equal_to: "height must be less than or equal to %{length} pixel."
      dimension_width_equal_to: "width must be equal to %{length} pixel."
      dimension_height_equal_to: "height must be equal to %{length} pixel."
```

In some cases Active Storage Validations provides variables to help you customize messages:

The "content_type_invalid" key has two variables that you can use, a variable named "content_type" containing the content type of the send file and a variable named "authorized_type" containing the list of authorized content types.

It's variables are not used by default to leave the choice to the user.

For example :

```yml
content_type_invalid: "has an invalid content type : %{content_type}"
```

Also the "limit_out_of_range" key supports two variables the "min" and "max".

For example :

```yml
limit_out_of_range: "total number is out of range. range: [%{min}, %{max}]"
```

## Installation

Add this line to your application's Gemfile:

```ruby

# Rails 5.2
gem 'active_storage_validations'

# >= Rails 6.0.0.RC.1
gem 'active_storage_validations', github: 'igorkasyanchuk/active_storage_validations', branch: 'rails.6.rc1.fix'

# Optional, to use :dimension validator
gem 'mini_magick', '>= 4.9.4'
```

And then execute:

```bash
$ bundle
```

## Sample

Very simple example of validation with file attached, content type check and custom error message.

[![Sample](https://raw.githubusercontent.com/igorkasyanchuk/active_storage_validations/master/docs/preview.png)](https://raw.githubusercontent.com/igorkasyanchuk/active_storage_validations/master/docs/preview.png)

## Todo

* verify with remote storages (s3, etc)
* verify how it works with direct upload
* better error message when content_size is invalid
* add more translations
* add aspect ratio validation

## Tests & Contributing

To run tests in root folder of gem:

* `BUNDLE_GEMFILE=gemfiles/rails_5_2.gemfile bundle exec rake test` to run for Rails 5.2
* `BUNDLE_GEMFILE=gemfiles/rails_6.0.gemfile bundle exec rake test` to run for Rails 6.0

To play with app `cd test/dummy` and `rails s -b 0.0.0.0` (before `rails db:migrate`).

## Known issues

- There is an issue in Rails which it possible to get if you have added a validation and generating for example an image preview of attachments. It can be fixed with this:

```
  <% if @user.avatar.attached? && @user.avatar.attachment.blob.present? && @user.avatar.attachment.blob.persisted? %>
    <%= image_tag @user.avatar %>
  <% end %>
```
This is Rails issue. And according to commits it will be fixed in Rails 6.

## Contributing
You are welcome to contribute.

## Contributors (BIG THANK YOU)
- https://github.com/schweigert
- https://github.com/tleneveu
- https://github.com/reckerswartz
- https://github.com/Uysim
- https://github.com/D-system
- https://github.com/ivanelrey
- https://github.com/phlegx

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
