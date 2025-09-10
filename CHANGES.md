- Unreleased

- 3.0.2
  - Fix issue with active_storage_validations metadata not being saved if only running a `valid?` call  (https://github.com/igorkasyanchuk/active_storage_validations/issues/361)
  - Fix issue with nested model update for Rails >= 8.0.2 (https://github.com/igorkasyanchuk/active_storage_validations/issues/377)
  - Fix typo for English dimension translations (https://github.com/igorkasyanchuk/active_storage_validations/issues/395)

- 3.0.1
  - Fix translation issues for German keys for pdf `pages` validator (`pages_not_greater_than_or_equal_to` / `pages_not_equal_to`)
  - Fix translation issues for Japanese keys (#https://github.com/igorkasyanchuk/active_storage_validations/issues/392)

- 3.0.0
  - Allow to perform dimension / aspect_ratio validations on single page pdf (https://github.com/igorkasyanchuk/active_storage_validations/pull/374)
  - Added `pages` validator to validate pdf number of pages (https://github.com/igorkasyanchuk/active_storage_validations/pull/374)
  - Added `equal_to` option to `duration`, `size`and `total_size` validators (https://github.com/igorkasyanchuk/active_storage_validations/pull/386)

  Version 3 comes with the ability to support single page pdf dimension / aspect_ratio analysis, we had to make a breaking change:
  - To analyze PDFs, you must install the `poppler` PDF processing dependency
    - It's a  Rails-supported PDF processing dependency (https://guides.rubyonrails.org/active_storage_overview.html#requirements)
    - To install it, check their documentation at this [link](https://pdf2image.readthedocs.io/en/latest/installation.html).
    - To check if it's installed, execute `pdftoppm -h`.
    - To install this tool in your CI / production environments, you can check how we do it in our own CI (https://github.com/igorkasyanchuk/active_storage_validations/blob/master/.github/workflows/main.yml)

  Note that, if you do not perform dimension / aspect_ratio validations on pdf, the gem will work the same as in version 2 without any breaking change.

- 2.0.4
  - Fix issue when updating a child record through a parent (like: parent_model.update(child_attributes: { image: file })) for Rails >= 8.0.2 (https://github.com/igorkasyanchuk/active_storage_validations/pull/378)
  - Fix issue causing a stack error too deep edge case (not reproductible) because of the `after: :load_config_initializers` option (https://github.com/igorkasyanchuk/active_storage_validations/pull/382)

- 2.0.3
  - Allow to pass an Array, a splatted Array, or a single string for allowing / rejecting content_type matcher methods (https://github.com/igorkasyanchuk/active_storage_validations/pull/372)
  - Fix issue when an attachment was missing on a blob (https://github.com/igorkasyanchuk/active_storage_validations/pull/373)

- 2.0.2
  - Fix undesirable mutation of Marcel::TYPE_EXTS (https://github.com/igorkasyanchuk/active_storage_validations/issues/356)
  - Fix gem loading issue with Marcel custom initialisers (https://github.com/igorkasyanchuk/active_storage_validations/issues/355)

- 2.0.1
  - Fix for invalid content type validation ([PR #347](https://github.com/igorkasyanchuk/active_storage_validations/pull/347))
  - Fix issue with custom_metadata not working with external services such as S3 ([PR #349](https://github.com/igorkasyanchuk/active_storage_validations/pull/349))
  - Fix issue when using several matchers using different metadata keys ([PR #351](https://github.com/igorkasyanchuk/active_storage_validations/pull/351))

- 2.0.0
  - We are happy to release the `active_storage_validations` version 2! This major version add several features such as:
    - Add support for video & audio files
      - `dimension` validator now supports video files
      - `aspect_ratio` validator now supports video files
      - `processable_image` validator is now `processable_file` validator and supports image/video/audio
    - New validator added:
      -  `duration` validator has been added for audio / video files
    - Major performance improvement have been added: we now only perform the expensive io analysis operation on the newly attached files
    - All error messages have been given an upgrade and new variables that you can use
    - Complete rewrite of gem README
  - To upgrade from version 1.x to 2.x, please read the [upgrade guide](https://github.com/igorkasyanchuk/active_storage_validations#upgrading-from-1x-to-2x) in the readme
  - Find the associated PRs here:
    - https://github.com/igorkasyanchuk/active_storage_validations/pull/310
    - https://github.com/igorkasyanchuk/active_storage_validations/pull/341

- 1.4.0
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/324
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/326
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/332
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/327
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/325
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/294

- 1.3.5
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/322
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/318
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/313
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/312
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/306
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/300
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/299

- 1.3.4
  Bug fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/296
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/297

- 1.3.3
  Bug fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/290/files
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/289/files
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/288/files

- 1.3.2
  Bug fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/284
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/285
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/286

- 1.3.0
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/256
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/268
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/267
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/263

- 1.2.0
  Many improvements and fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/236
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/237
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/238
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/240
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/245
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/248
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/251
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/250
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/247
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/252
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/253
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/262


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
  - Added Vietnamese translation https://github.com/igorkasyanchuk/active_storage_validations/pull/108
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
  - fixed error messages for aspect ratio validation PR #44
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
