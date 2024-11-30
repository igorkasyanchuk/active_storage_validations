[<img src="https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/more_gems.png?raw=true"
/>](https://www.railsjazz.com/?utm_source=github&utm_medium=top&utm_campaign=active_storage_validations)

# Active Storage Validations

[![MiniTest](https://github.com/igorkasyanchuk/active_storage_validations/workflows/MiniTest/badge.svg)](https://github.com/igorkasyanchuk/active_storage_validations/actions)
[![RailsJazz](https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/my_other.svg?raw=true)](https://www.railsjazz.com)
[![https://www.patreon.com/igorkasyanchuk](https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/patron.svg?raw=true)](https://www.patreon.com/igorkasyanchuk)
[![Listed on OpenSource-Heroes.com](https://opensource-heroes.com/badge-v1.svg)](https://opensource-heroes.com/r/igorkasyanchuk/active_storage_validations)


Active Storage Validations is a gem that allows you to add validations for Active Storage attributes.

This gems is doing it right for you! Just use `validates :avatar, attached: true, content_type: 'image/png'` and that's it!

## Table of Contents

- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Error messages (I18n)](#error-messages-i18n)
  - [Using image metadata validators](#using-image-metadata-validators)
  - [Using video and audio metadata validators](#using-video-and-audio-metadata-validators)
- [Validators](#validators)
  - [Attached](#attached)
  - [Limit](#limit)
  - [Content type](#content-type)
  - [Size](#size)
  - [Total size](#total-size)
  - [Dimension](#dimension)
  - [Aspect ratio](#aspect-ratio)
  - [Processable image](#processable-image)
- [Upgrading from 1.x to 2.x](#upgrading-from-1x-to-2x)
- [Usage](#usage)
- [Internationalization (I18n)](#internationalization-i18n)
- [Test matchers](#test-matchers)
- [Tests & Contributing](#tests--contributing)
- [Additional information](#additional-information)

## Getting started

### Installation

Active Storage Validations work with Rails 6.1.4 onwards. Add this line to your application's Gemfile:

```ruby
gem 'active_storage_validations'
```

And then execute:

```sh
$ bundle
```

### Error messages (I18n)

Once you have installed the gem, you need to add the gem I18n error messages to your app. See [Internationalization (I18n)](#internationalization-i18n) section for more details.

### Using image metadata validators

Optionally, to use the image metadata validators (`dimension`, `aspect_ratio` and `processable_image`), you will have to add one of the corresponding gems:

```ruby
gem 'mini_magick', '>= 4.9.5'
# Or
gem 'ruby-vips', '>= 2.1.0'
```

Plus, you have to be sure to have the corresponding command-line tool installed on your system. For example, to use `mini_magick` gem, you need to have `imagemagick` installed on your system (both on your local and in your CI / production environments).

### Using video and audio metadata validators

To use the video and audio metadata validators (`dimension`, `aspect_ratio` and `duration`), you will not need to add any gems. However you will need to have the `ffmpeg` command-line tool installed on your system (once again, be sure to have it installed both on your local and in your CI / production environments).

## Validators

List of validators:
- [Attached](#attached): validates if file(s) attached
- [Limit](#limit): validates number of uploaded files
- [Content type](#content-type): validates file content type
- [Size](#size): validates file size
- [Total size](#total-size): validates total file size for several files
- [Dimension](#dimension): validates image / video dimensions
- [Aspect ratio](#aspect-ratio): validates image / video aspect ratio
- [Processable image](#processable-image): validates if an image can be processed

**Proc usage**

Every validator can use procs instead of values in all the validator examples:
```ruby
class User < ApplicationRecord
  has_many_attached :files

  validates :files, limit: { max: -> (record) { record.admin? ? 100 : 10 } }
end
```

---

### Attached

Validates if the attachment is present.

#### Options

The `attached` validator has no options.

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, attached: true
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      blank: "can't be blank"
```

The error message for this validator relies on Rails own `blank` error message.

---

### Limit

Validates the number of uploaded files.

#### Options

The `limit` validator has several options:
- `min`: defines the minimum allowed number of files
- `max`: defines the maximum allowed number of files

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_many_attached :certificates

  validates :certificates, limit: { min: 1, max: 10 } # restricts the number of files to between 1 and 10
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      limit_out_of_range: "total number is out of range"
```

The `limit` validator error messages expose 2 values that you can use:
- `min` containing the minimum allowed number of files (e.g. `1`)
- `max` containing the maximum allowed number of files (e.g. `10`)

---

### Content type

Validates if the attachment has an allowed content type.

#### Options

The `content_type` validator has several options:
- `with`: defines the exact allowed content type (string, symbol or regex)
- `in`: defines the allowed content types (array of strings or symbols)
- `spoofing_protection`: enables content type spoofing protection (boolean, defaults to `false`)

As mentioned above, this validator can define content types in several ways:
- String: `image/png` or `png`
- Symbol: `:png`
- Regex: `/\Avideo\/.*\z/`

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, content_type: 'image/png' # only allows PNG images
  validates :avatar, content_type: :png # only allows PNG images
  validates :avatar, content_type: /\Avideo\/.*\z/ # only allows video files
  validates :avatar, content_type: ['image/png', 'image/jpeg'] # only allows PNG and JPEG images
  validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: true } # only allows PNG, JPEG and their variants, with spoofing protection enabled
end
```

#### Content type shorthands

If you choose to use a content_type 'shorthand' (like `png`), note that it will be converted to a full content type using `Marcel::MimeType.for` under the hood. Therefore, you should check if the content_type is registered by [`Marcel::EXTENSIONS`](https://github.com/rails/marcel/blob/main/lib/marcel/tables.rb). If it's not, you can register it by adding the following code to your `config/initializers/mime_types.rb` file:
```ruby
Marcel::MimeType.extend "application/ino", extensions: %w(ino), parents: "text/plain" # Registering arduino INO files
```

#### Content type spoofing protection

By default, the gem does not prevent content type spoofing. You can enable it by setting the `spoofing_protection` option to `true` in your validator options.

##### What is content type spoofing?
File content type spoofing happens when an ill-intentioned user uploads a file which hides its true content type by faking its extension and its declared content type value. For example, a user may try to upload a `.exe` file (application/x-msdownload content type) dissimulated as a `.jpg` file (image/jpeg content type).

##### How do we prevent it?
The spoofing protection relies on both the linux `file` command and `Marcel` gem. Be careful, since it needs to load the whole file io to perform the analysis, it will use a lot of RAM for very large files. Therefore it could be a wise decision not to enable it in this case.

Take note that the `file` analyzer will not find the exactly same content type as the ActiveStorage blob (ActiveStorage content type detection relies on a different logic using content+filename+extension). To handle this issue, we consider a close parent content type to be a match. For example, for an ActiveStorage blob which content type is `video/x-ms-wmv`, the `file` analyzer will probably detect a `video/x-ms-asf` content type, this will be considered as a valid match because these 2 content types are closely related. The correlation mapping is based on `Marcel::TYPE_PARENTS`.

##### Edge cases
The difficulty to accurately predict a mime type may generate false positives, if so there are two solutions available:
- If the ActiveStorage blob content type is closely related to the detected content type using the `file` analyzer, you can enhance `Marcel::TYPE_PARENTS` mapping using `Marcel::MimeType.extend "application/x-rar-compressed", parents: %(application/x-rar)` in the `config/initializers/mime_types.rb` file. (Please drop an issue so we can add it to the gem for everyone!)
- If the ActiveStorage blob content type is not closely related, you still can disable the content type spoofing protection in the validator, if so, please drop us an issue so we can fix it for everyone!

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      content_type_invalid: "has an invalid content type"
```

The `content_type` validator error messages expose 4 values that you can use:
- `content_type` containing the exact content type of the sent file (e.g. `image/png`)
- `human_content_type` containing a more user-friendly version of the sent file content type (e.g. 'TXT' for 'text/plain')
- `authorized_types` containing the list of authorized content types (e.g. 'PNG, JPEG' for `['image/png', 'image/jpeg']`)
- `filename` containing the filename

---

### Size

Validates each attached file size.

#### Options

The `size` validator has several options:
- `less_than`: defines the strict maximum allowed file size
- `less_than_or_equal_to`: defines the maximum allowed file size
- `greater_than`: defines the strict minimum allowed file size
- `greater_than_or_equal_to`: defines the minimum allowed file size
- `between`: defines the allowed file size range

It is always a good practice to limit the maximum file size to a reasonable value (like 2MB for avatar images).

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, size: { less_than: 2.megabytes } # restricts the file size to < 2MB
  validates :avatar, size: { less_than_or_equal_to: 2.megabytes } # restricts the file size to <= 2MB
  validates :avatar, size: { greater_than: 1.kilobyte } # restricts the file size to > 1KB
  validates :avatar, size: { greater_than_or_equal_to: 1.kilobyte } # restricts the file size to >= 1KB
  validates :avatar, size: { between: 1.kilobyte..2.megabytes } # restricts the file size to between 1KB and 2MB
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      file_size_not_less_than: "file size must be less than %{max_size} (current size is %{file_size})"
      file_size_not_less_than_or_equal_to: "file size must be less than or equal to %{max_size} (current size is %{file_size})"
      file_size_not_greater_than: "file size must be greater than %{min_size} (current size is %{file_size})"
      file_size_not_greater_than_or_equal_to: "file size must be greater than or equal to %{min_size} (current size is %{file_size})"
      file_size_not_between: "file size must be between %{min_size} and %{max_size} (current size is %{file_size})"
```

The `size` validator error messages expose 4 values that you can use:
- `file_size` containing the current file size (e.g. `1.5MB`)
- `min` containing the minimum allowed file size (e.g. `1KB`)
- `max` containing the maximum allowed file size (e.g. `2MB`)
- `filename` containing the current file name

---

### Total size

Validates the total file size for several files.

#### Options

The `total_size` validator has several options:
- `less_than`: defines the strict maximum allowed total file size
- `less_than_or_equal_to`: defines the maximum allowed total file size
- `greater_than`: defines the strict minimum allowed total file size
- `greater_than_or_equal_to`: defines the minimum allowed total file size
- `between`: defines the allowed total file size range

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_many_attached :certificates

  validates :certificates, total_size: { less_than: 10.megabytes } # restricts the total size to < 10MB
  validates :certificates, total_size: { less_than_or_equal_to: 10.megabytes } # restricts the total size to <= 10MB
  validates :certificates, total_size: { greater_than: 1.kilobyte } # restricts the total size to > 1KB
  validates :certificates, total_size: { greater_than_or_equal_to: 1.kilobyte } # restricts the total size to >= 1KB
  validates :certificates, total_size: { between: 1.kilobyte..10.megabytes } # restricts the total size to between 1KB and 10MB
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      total_file_size_not_less_than: "total file size must be less than %{max_size} (current size is %{total_file_size})"
      total_file_size_not_less_than_or_equal_to: "total file size must be less than or equal to %{max_size} (current size is %{total_file_size})"
      total_file_size_not_greater_than: "total file size must be greater than %{min_size} (current size is %{total_file_size})"
      total_file_size_not_greater_than_or_equal_to: "total file size must be greater than or equal to %{min_size} (current size is %{total_file_size})"
      total_file_size_not_between: "total file size must be between %{min_size} and %{max_size} (current size is %{total_file_size})"
```

The `total_size` validator error messages expose 4 values that you can use:
- `file_size` containing the current file size (e.g. `1.5MB`)
- `min` containing the minimum allowed total file size (e.g. `1KB`)
- `max` containing the maximum allowed total file size (e.g. `2MB`)

---

### Dimension

Validates the dimension of the attached files.

#### Options

The `dimension` validator has several options:
- `width`: defines the exact allowed width (integer)
  - `min`: defines the minimum allowed width (integer)
  - `max`: defines the maximum allowed width (integer)
  - `in`: defines the allowed width range (range)
- `height`: defines the exact allowed height (integer)
  - `min`: defines the minimum allowed height (integer)
  - `max`: defines the maximum allowed height (integer)
  - `in`: defines the allowed height range (range)
- `min`: defines the minimum allowed width and height (range)
- `max`: defines the maximum allowed width and height (range)

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, dimension: { width: 100 } # restricts the width to 100 pixels
  validates :avatar, dimension: { width: { min: 80, max: 100 } } # restricts the width to between 80 and 100 pixels
  validates :avatar, dimension: { width: { in: 80..100 } } # restricts the width to between 80 and 100 pixels
  validates :avatar, dimension: { height: 100 } # restricts the height to 100 pixels
  validates :avatar, dimension: { height: { min: 600, max: 1800 } } # restricts the height to between 600 and 1800 pixels
  validates :avatar, dimension: { height: { in: 600..1800 } } # restricts the height to between 600 and 1800 pixels
  validates :avatar, dimension: { min: 80..600, max: 100..1800 } # restricts the width to between 80 and 100 pixels, and the height to between 600 and 1800 pixels
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      dimension_min_inclusion: "must be greater than or equal to %{width} x %{height} pixel"
      dimension_max_inclusion: "must be less than or equal to %{width} x %{height} pixel"
      dimension_width_inclusion: "width is not included between %{min} and %{max} pixel"
      dimension_height_inclusion: "height is not included between %{min} and %{max} pixel"
      dimension_width_greater_than_or_equal_to: "width must be greater than or equal to %{length} pixel"
      dimension_height_greater_than_or_equal_to: "height must be greater than or equal to %{length} pixel"
      dimension_width_less_than_or_equal_to: "width must be less than or equal to %{length} pixel"
      dimension_height_less_than_or_equal_to: "height must be less than or equal to %{length} pixel"
      dimension_width_equal_to: "width must be equal to %{length} pixel"
      dimension_height_equal_to: "height must be equal to %{length} pixel"
```

The `dimension` validator error messages expose 6 values that you can use:
- `min` containing the minimum width or height allowed
- `max` containing the maximum width or height allowed
- `width` containing the minimum or maximum width allowed
- `height` containing the minimum or maximum width allowed
- `length` containing the exact width or height allowed
- `filename` containing the current filename in error

---

### Aspect ratio

---

### Processable image

---

## Upgrading from 1.x to 2.x

If you are upgrading from 1.x to 2.x, you will be pleased to note that a lot of things have been added and improved!

Added features:
- `dimension` validator now supports videos
- `aspect_ratio` validator now supports videos

But this major version bump also comes with some breaking changes. Below are the main breaking changes you need to be aware of:
- Error messages
  - The error messages have been completely rewritten to be more consistent and easier to understand.
  - Some error messages variables names have been changed to improve readability:
    - `dimension` validator:
      - `length` has been replaced by `exact`

🚧 TODO: Add more details about the other changes when implemented


## What it can do

<!-- * validates if file(s) attached -->
<!-- * validates content type -->
<!-- * validates size of files -->
<!-- * validates total size of files -->
<!-- * validates dimension of images/videos -->
<!-- * validates number of uploaded files (min/max required) -->
* validates aspect ratio (if square, portrait, landscape, is_16_9, ...)
* validates if file can be processed by MiniMagick or Vips
<!-- * custom error messages -->
<!-- * allow procs for dynamic determination of values -->

## Usage

For example you have a model like this and you want to add validation.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos
  has_one_attached :image

  validates :name, presence: true

  validates :avatar, attached: true, content_type: 'image/png',
                                     dimension: { width: 200, height: 200 }
  validates :photos, attached: true, content_type: ['image/png', 'image/jpeg'],
                                     dimension: { width: { min: 800, max: 2400 },
                                                  height: { min: 600, max: 1800 }, message: 'is not given between dimension' }
  validates :image, attached: true,
                    processable_image: true,
                    content_type: ['image/png', 'image/jpeg'],
                    aspect_ratio: :landscape
end
```

or

```ruby
class Project < ApplicationRecord
  has_one_attached :logo
  has_one_attached :preview
  has_one_attached :attachment
  has_many_attached :documents

  validates :title, presence: true

  validates :logo, attached: true, size: { less_than: 100.megabytes , message: 'is too large' }
  validates :preview, attached: true, size: { between: 1.kilobyte..100.megabytes , message: 'is not given between size' }
  validates :attachment, attached: true, content_type: { in: 'application/pdf', message: 'is not a PDF' }
  validates :documents, limit: { min: 1, max: 3 }, total_size: { less_than: 5.megabytes }
end
```

### More examples


- Aspect ratio validation:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_one_attached :photo
  has_many_attached :photos

  validates :avatar, aspect_ratio: :square
  validates :photo, aspect_ratio: :landscape

  # you can also pass dynamic aspect ratio, like :is_4_3, :is_16_9, etc
  validates :photos, aspect_ratio: :is_4_3
end
```


## Internationalization (I18n)

Active Storage Validations uses I18n for error messages. For this, add these keys in your translation file:

```yml
en:
  errors:
    messages:
      content_type_invalid: "has an invalid content type"
      file_size_not_less_than: "file size must be less than %{max_size} (current size is %{file_size})"
      file_size_not_less_than_or_equal_to: "file size must be less than or equal to %{max_size} (current size is %{file_size})"
      file_size_not_greater_than: "file size must be greater than %{min_size} (current size is %{file_size})"
      file_size_not_greater_than_or_equal_to: "file size must be greater than or equal to %{min_size} (current size is %{file_size})"
      file_size_not_between: "file size must be between %{min_size} and %{max_size} (current size is %{file_size})"
      total_file_size_not_less_than: "total file size must be less than %{max_size} (current size is %{total_file_size})"
      total_file_size_not_less_than_or_equal_to: "total file size must be less than or equal to %{max_size} (current size is %{total_file_size})"
      total_file_size_not_greater_than: "total file size must be greater than %{min_size} (current size is %{total_file_size})"
      total_file_size_not_greater_than_or_equal_to: "total file size must be greater than or equal to %{min_size} (current size is %{total_file_size})"
      total_file_size_not_between: "total file size must be between %{min_size} and %{max_size} (current size is %{total_file_size})"
      limit_out_of_range: "total number is out of range"
      image_metadata_missing: "is not a valid image"
      dimension_min_inclusion: "must be greater than or equal to %{width} x %{height} pixel"
      dimension_max_inclusion: "must be less than or equal to %{width} x %{height} pixel"
      dimension_width_inclusion: "width is not included between %{min} and %{max} pixel"
      dimension_height_inclusion: "height is not included between %{min} and %{max} pixel"
      dimension_width_greater_than_or_equal_to: "width must be greater than or equal to %{length} pixel"
      dimension_height_greater_than_or_equal_to: "height must be greater than or equal to %{length} pixel"
      dimension_width_less_than_or_equal_to: "width must be less than or equal to %{length} pixel"
      dimension_height_less_than_or_equal_to: "height must be less than or equal to %{length} pixel"
      dimension_width_equal_to: "width must be equal to %{length} pixel"
      dimension_height_equal_to: "height must be equal to %{length} pixel"
      aspect_ratio_not_square: "must be a square image"
      aspect_ratio_not_portrait: "must be a portrait image"
      aspect_ratio_not_landscape: "must be a landscape image"
      aspect_ratio_is_not: "must have an aspect ratio of %{aspect_ratio}"
      image_not_processable: "is not a valid image"
```

In several cases, Active Storage Validations provides variables to help you customize messages:

### Aspect ratio
The keys starting with `aspect_ratio_` support two variables that you can use:
- `aspect_ratio` containing the expected aspect ratio, especially useful for custom aspect ratio
- `filename` containing the current file name

For example :

```yml
aspect_ratio_is_not: "must be a %{aspect_ratio} image"
```

### Processable image
The `image_not_processable` key supports one variable that you can use:
- `filename` containing the current file name

For example :

```yml
image_not_processable: "is not a valid image (file: %{filename})"
```

## Sample

Very simple example of validation with file attached, content type check and custom error message.

[![Sample](https://raw.githubusercontent.com/igorkasyanchuk/active_storage_validations/master/docs/preview.png)](https://raw.githubusercontent.com/igorkasyanchuk/active_storage_validations/master/docs/preview.png)

## Test matchers
Provides RSpec-compatible and Minitest-compatible matchers for testing the validators.

### RSpec

In `spec_helper.rb`, you'll need to require the matchers:

```ruby
require 'active_storage_validations/matchers'
```

And _include_ the module:

```ruby
RSpec.configure do |config|
  config.include ActiveStorageValidations::Matchers
end
```

Matcher methods available:

```ruby
describe User do
  # aspect_ratio:
  # #allowing, #rejecting
  it { is_expected.to validate_aspect_ratio_of(:avatar).allowing(:square) }
  it { is_expected.to validate_aspect_ratio_of(:avatar).rejecting(:portrait) }

  # attached
  it { is_expected.to validate_attached_of(:avatar) }

  # processable_image
  it { is_expected.to validate_processable_image_of(:avatar) }

  # limit
  # #min, #max
  it { is_expected.to validate_limits_of(:avatar).min(1) }
  it { is_expected.to validate_limits_of(:avatar).max(5) }

  # content_type:
  # #allowing, #rejecting
  it { is_expected.to validate_content_type_of(:avatar).allowing('image/png', 'image/gif') }
  it { is_expected.to validate_content_type_of(:avatar).rejecting('text/plain', 'text/xml') }

  # dimension:
  # #width, #height, #width_min, #height_min, #width_max, #height_max, #width_between, #height_between
  it { is_expected.to validate_dimensions_of(:avatar).width(250) }
  it { is_expected.to validate_dimensions_of(:avatar).height(200) }
  it { is_expected.to validate_dimensions_of(:avatar).width_min(200) }
  it { is_expected.to validate_dimensions_of(:avatar).height_min(100) }
  it { is_expected.to validate_dimensions_of(:avatar).width_max(500) }
  it { is_expected.to validate_dimensions_of(:avatar).height_max(300) }
  it { is_expected.to validate_dimensions_of(:avatar).width_between(200..500) }
  it { is_expected.to validate_dimensions_of(:avatar).height_between(100..300) }

  # size:
  # #less_than, #less_than_or_equal_to, #greater_than, #greater_than_or_equal_to, #between
  it { is_expected.to validate_size_of(:avatar).less_than(50.kilobytes) }
  it { is_expected.to validate_size_of(:avatar).less_than_or_equal_to(50.kilobytes) }
  it { is_expected.to validate_size_of(:avatar).greater_than(1.kilobyte) }
  it { is_expected.to validate_size_of(:avatar).greater_than_or_equal_to(1.kilobyte) }
  it { is_expected.to validate_size_of(:avatar).between(100..500.kilobytes) }

  # total_size:
  # #less_than, #less_than_or_equal_to, #greater_than, #greater_than_or_equal_to, #between
  it { is_expected.to validate_total_size_of(:avatar).less_than(50.kilobytes) }
  it { is_expected.to validate_total_size_of(:avatar).less_than_or_equal_to(50.kilobytes) }
  it { is_expected.to validate_total_size_of(:avatar).greater_than(1.kilobyte) }
  it { is_expected.to validate_total_size_of(:avatar).greater_than_or_equal_to(1.kilobyte) }
  it { is_expected.to validate_total_size_of(:avatar).between(100..500.kilobytes) }
end
```
(Note that matcher methods are chainable)

All matchers can currently be customized with Rails validation options:

```ruby
describe User do
  # :allow_blank
  it { is_expected.to validate_attached_of(:avatar).allow_blank }

  # :on
  it { is_expected.to validate_attached_of(:avatar).on(:update) }
  it { is_expected.to validate_attached_of(:avatar).on(%i[update custom]) }

  # :message
  it { is_expected.to validate_dimensions_of(:avatar).width(250).with_message('Invalid dimensions.') }
end
```

### Minitest
To use the matchers, make sure you have the [shoulda-context](https://github.com/thoughtbot/shoulda-context) gem up and running.

You need to require the matchers:

```ruby
require 'active_storage_validations/matchers'
```

And _extend_ the module:

```ruby
class ActiveSupport::TestCase
  extend ActiveStorageValidations::Matchers
end
```

Then you can use the matchers with the syntax specified in the RSpec section, just use `should validate_method` instead of `it { is_expected_to validate_method }` as specified in the [shoulda-context](https://github.com/thoughtbot/shoulda-context) gem.


## Tests & Contributing

To run tests in root folder of gem:

* `BUNDLE_GEMFILE=gemfiles/rails_6_1_4.gemfile bundle exec rake test` to run for Rails 7.0
* `BUNDLE_GEMFILE=gemfiles/rails_7_0.gemfile bundle exec rake test` to run for Rails 7.0
* `BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rake test` to run for Rails 7.1
* `BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rake test` to run for Rails 7.2
* `BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle exec rake test` to run for Rails 8.0

Snippet to run in console:

```bash
BUNDLE_GEMFILE=gemfiles/rails_6_1_4.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_0.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_6_1_4.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_7_0.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle exec rake test
```

Tips:
- To focus a specific test, use the `focus` class method provided by [minitest-focus](https://github.com/minitest/minitest-focus)
- To focus a specific file, use the TEST option provided by minitest, e.g. to only run size_validator_test.rb file you will execute the following command: `bundle exec rake test TEST=test/validators/size_validator_test.rb`


## Additional information

### Contributors (BIG THANK YOU!)

We have a long list of valued contributors. Check them all at:

https://github.com/igorkasyanchuk/active_storage_validations/graphs/contributors

### License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

<br>

[<img src="https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/more_gems.png?raw=true"
/>](https://www.railsjazz.com/?utm_source=github&utm_medium=bottom&utm_campaign=active_storage_validations)
