# Active Storage Validations

If you are using `active_storage` gem and you want to add simple validations for it, like presence or content_type you need to write a custom valiation method.

This gems doing it for you. Just use `attached: true` or `content_type: 'image/png'` validation.

## What it can do

* validates if file(s) attached
* validates content type
* validates size of files
* validates number of uploaded files (min/max required)
* custom error messages

## Usage

For example you have a model like this and you want to add validation.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos

  validates :name, presence: true

  validates :avatar, attached: true, content_type: 'image/png'
  validates :photos, attached: true, content_type: ['image/png', 'image/jpg', 'image/jpeg']
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

## Internationalization (I18n)

Active Storage Validations use I18n for errors messages. For this add there keys in your translation file :

```yml
en:
  errors:
    messages:
      content_type_invalid: "has an invalid content type"
      limit_out_of_range: "total number is out of range"
```

In some cases Active Storage Validations provides variables to help you customize messages :

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
* verify with remote storages (s3, etc)
* verify how it works with direct upload 
* better error message when  content_size is invalid

## Tests & Contributing

To run tests in root folder of gem `rake test`.

To play with app `cd test/dummy` and `rails s -b 0.0.0.0` (before `rails db:migrate`).

## Known issues

- there is an issue in Rails which it possible to get if you have aadded a validation and generating for example an image preview of atachments. It can be fixed with this:

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

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
