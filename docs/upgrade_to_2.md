# Upgrading to 2.x

If you are upgrading from 1.x to 2.x, you will be pleased to note that a lot of things have been added and improved!

Added features:
- `duration` validator has been added for audio / video files
- `dimension` validator now supports videos
- `aspect_ratio` validator now supports videos
- `processable_image` validator is now `processable_file` validator and supports image/video/audio
- Major performance improvement have been added: we now only perform the expensive io analysis operation on the newly attached files. For previously attached files, we validate them using Rails `ActiveStorage::Blob#metadata` internal mecanism ([more here](https://github.com/rails/rails/blob/main/activestorage/app/models/active_storage/blob/analyzable.rb)).
- All error messages have been given an upgrade and new variables that you can use

But this major version bump also comes with some breaking changes. Below are the main breaking changes you need to be aware of:
- Error messages
  - We advise you to replace all the v1 translations by the new v2 rather than changing them one by one. A majority of messages have been completely rewritten to be more consistent and easier to understand.
  - If you wish to change them one by one, here is the list of changes to make:
    - Some validator errors have been totally changed:
      - `limit` validator keys have been totally reworked
      - `dimension` validator keys have been totally reworked
      - `content_type` validator keys have been totally reworked
      - `processable_image` validator keys have been totally reworked
    - Some keys have been changed:
      - `image_metadata_missing` has been replaced by `media_metadata_missing`
      - `aspect_ratio_is_not` has been replaced by `aspect_ratio_not_x_y`
    - Some error messages variables names have been changed to improve readability:
      - `aspect_ratio` validator:
        - `aspect_ratio` has been replaced by `authorized_aspect_ratios`
      - `content_type` validator:
        - `authorized_types` has been replaced by `authorized_human_content_types`
      - `size` validator:
        - `min_size` has been replaced by `min`
        - `max_size` has been replaced by `max`
      - `total_size` validator:
        - `min_size` has been replaced by `min`
        - `max_size` has been replaced by `max`

- `content_type` validator
  - The `:in` option now only accepts 'valid' content types (ie content types deemed by Marcel as valid).
    - The check was mistakenly only performed on the `:with` option previously. Therefore, invalid content types were accepted in the `:in` option, which is not the expected behavior.
    - This might break some cases when you had for example `content_type: ['image/png', 'image/jpg']`, because `image/jpg` is not a valid content type, it should be replaced by `image/jpeg`.
  - An `ArgumentError` is now raised if `image/jpg` is used to make it easier to fix. You should now only use `image/jpeg`.

- `processable_image` validator
  - The validator has been replaced by `processable_file` validator, be sure to replace `processable_image: true` to `processable_file: true`
  - The associated matcher has also been updated accordingly, be sure to replace `validate_processable_image_of` to `validate_processable_file_of`
