- master

- 1.1.4
  Many improvements and fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/235
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/233
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/232
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/229
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/228
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/226
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/161
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/153
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/221
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/220


- 1.1.3
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/217/files
  - drop Rails 6.0 from CI
  - added Rails 7.1 to CI

- 1.1.2
  - https://github.com/igorkasyanchuk/active_storage_validations/issues/213
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/214
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/206
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/208

- 1.1.1
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/202

- 1.0.4
  - Support for StringIO attachments https://github.com/igorkasyanchuk/active_storage_validations/pull/176
  - Support libvips < 8.8 https://github.com/igorkasyanchuk/active_storage_validations/pull/185
  - Test against Ruby 3.2

- 1.0.3
  - Fix missing block when using valid? method https://github.com/igorkasyanchuk/active_storage_validations/pull/174

- 1.0.2
  - Support using allowing and rejecting together on content type matcher https://github.com/igorkasyanchuk/active_storage_validations/pull/172

- 1.0.1
  - add ProcessableImageValidator https://github.com/igorkasyanchuk/active_storage_validations/pull/168
  - fix slowness https://github.com/igorkasyanchuk/active_storage_validations/pull/169

- 1.0.0
  - allow Procs as an input for validation options https://github.com/igorkasyanchuk/active_storage_validations/pull/135/files
  - new translation zh-CN https://github.com/igorkasyanchuk/active_storage_validations/pull/162
  - drop support of Rails 5.2 (in tests, but in reality it should work, just check PR in this version)

- 0.9.8
  - Fix a file extension issue in Metadata#read_image https://github.com/igorkasyanchuk/active_storage_validations/pull/148/files
  - Dynamic exception class https://github.com/igorkasyanchuk/active_storage_validations/pull/150
  - Display All Validation Errors https://github.com/igorkasyanchuk/active_storage_validations/pull/152

- 0.9.7
  - tests for Rails 7 and Ruby 3.1 https://github.com/igorkasyanchuk/active_storage_validations/pull/143
  - Fix pt-BR translations https://github.com/igorkasyanchuk/active_storage_validations/pull/132
  - Remove references to image/jpg content type https://github.com/igorkasyanchuk/active_storage_validations/pull/144
  - missing relationship in dummy app https://github.com/igorkasyanchuk/active_storage_validations/pull/142
  - References Marcel::TYPES only for Rails < 6.1 https://github.com/igorkasyanchuk/active_storage_validations/pull/138
  - better clarify how to define between size https://github.com/igorkasyanchuk/active_storage_validations/pull/133
  - Add vips support for aspect ratio and dimension validators https://github.com/igorkasyanchuk/active_storage_validations/pull/140

- 0.9.6
  - Add min_size and max_size to :file_size_out_of_range error message https://github.com/igorkasyanchuk/active_storage_validations/pull/134
  - Reference Marcel::EXTENSIONS https://github.com/igorkasyanchuk/active_storage_validations/pull/137

- 0.9.5
  - add latest Rails support in tests https://github.com/igorkasyanchuk/active_storage_validations/pull/126
  - file permissions set to 0644 https://github.com/igorkasyanchuk/active_storage_validations/pull/125
  - use Marcel to detect the correct content_type https://github.com/igorkasyanchuk/active_storage_validations/pull/123
  - enable CI for pull requests https://github.com/igorkasyanchuk/active_storage_validations/pull/124

- 0.9.4
  - Add with_message for dimension_validator_matcher  https://github.com/igorkasyanchuk/active_storage_validations/pull/117
  - Fix typo in tests https://github.com/igorkasyanchuk/active_storage_validations/pull/119
  - Raise error when undefined mime type symbol is given https://github.com/igorkasyanchuk/active_storage_validations/pull/120
  - Enable to set message on error of attached validator https://github.com/igorkasyanchuk/active_storage_validations/pull/121


- 0.9.3
  - Addded Vietnamese translation https://github.com/igorkasyanchuk/active_storage_validations/pull/108
  - Allow regex in content_type arrays https://github.com/igorkasyanchuk/active_storage_validations/pull/104
  - fixes for spanish translation https://github.com/igorkasyanchuk/active_storage_validations/pull/114, https://github.com/igorkasyanchuk/active_storage_validations/pull/115/

- 0.9.2
  - moved to github actions (@StefSchenkelaars)
  - better support for ruby 3, rails 6.1 (@StefSchenkelaars)

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
