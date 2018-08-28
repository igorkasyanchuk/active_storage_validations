# ActiveStorage Validations

If you are using `active_storage` gem and you want to add simple validations for it, like presence or content_type you need to write a custom valiation method.

This gems doing it for you. Just use `attached: true` or `content_type: 'image/png'` validation.

## Usage

For example you have a model like this and you want to add validation.

```
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos

  validates :name, presence: true

  validates :avatar, attached: true, content_type: 'image/png'
  validates :photos, attached: true, content_type: ['image/png', 'image/jpg']
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

## Tests & Contributing

To run tests in root folder of gem `rake test`.

To play with app `cd test/dummy` and `rails s -b 0.0.0.0` (before `rake db:migrate`).

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
