- master

- 0.9.1
  - ensure to detach attachment before validating attached https://github.com/igorkasyanchuk/active_storage_validations/pull/81
  - fixing UK translations https://github.com/igorkasyanchuk/active_storage_validations/pull/92
  - added ES translation https://github.com/igorkasyanchuk/active_storage_validations/pull/90
  - Rails 6.1 support https://github.com/igorkasyanchuk/active_storage_validations/pull/94
  - added dutch translation https://github.com/igorkasyanchuk/active_storage_validations/pull/97
  - fix deprecation warnings for Ruby 2.7 https://github.com/igorkasyanchuk/active_storage_validations/pull/100

- 0.9.0
  - added Turkish translation https://github.com/igorkasyanchuk/active_storage_validations/pull/75
  - fixed attached matcher https://github.com/igorkasyanchuk/active_storage_validations/pull/79

- 0.8.9
  - better DE translations

- 0.8.8
  - Fix something wrong with params: https://github.com/igorkasyanchuk/active_storage_validations/pull/66 @High5Apps
  - added Janapese language (@willnet)

- 0.8.7
  - added test matchers https://github.com/igorkasyanchuk/active_storage_validations/pull/56

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
