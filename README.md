# ActiveStorage Validations

If you are using `active_storage` gem and you want to add simple validations for it, like presence or content_type you need to write a custom valiation method.

This gems doing it for you. Just use `attached: true` or `content_type: 'image/png'` validation.

## Usage

For example you have a model like this and you want to add validation.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos

  validates :name, presence: true

  validates :avatar, attached: true, content_type: 'image/png'
  validates :photos, attached: true, content_type: ['image/png', 'image/jpg']
end
```

or

```ruby
class Project < ApplicationRecord
  has_one_attached :preview
  has_one_attached :attachment

  validates :title, presence: true

  validates :preview, attached: true
  validates :attachment, attached: true, content_type: { in: 'application/pdf', message: 'is not a PDF' }
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_storage_validations'
```

And then execute:
```bash
$ bundle
```

## Sample

Very simple example of validation with file attached, content type check and custom error message.

[![Sample](https://raw.githubusercontent.com/igorkasyanchuk/active_storage_validations/master/docs/preview.png)](https://raw.githubusercontent.com/igorkasyanchuk/active_storage_validations/master/docs/preview.png)

## Todo
* verify with remote storages
* better error message when content_type is invalid
* travis CI
* validation for file size

## Tests & Contributing

To run tests in root folder of gem `rake test`.

To play with app `cd test/dummy` and `rails s -b 0.0.0.0` (before `rake db:migrate`).

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
