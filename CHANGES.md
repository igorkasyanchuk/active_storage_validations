- master
  - ...

- 0.8.6
  - added FR, RU, UK translations

- 0.8.5
  - small tweaks

- 0.8.4
  - fixed error messages for aspect ratio valiation PR #44
  - better limit validation for rails 6 PR #45

- 0.8.3
  - added pt-BR translation PR #40

- 0.8.2
  - allows to pass Regexp for a content type validation: `validates :avatar, content_type: /\Aimage\/.*\z/`

- 0.8.1
  - allows to pass symbol for a content type validation: `validates :avatar, attached: true, content_type: :png`

- 0.8.0
  - added aspect ratio validator
  - support for Rails 5.2 and Rails 6

- 0.7.1
  - added dimension validator