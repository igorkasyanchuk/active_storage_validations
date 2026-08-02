# Upgrading to 3.x

Version 3 comes with the ability to support single page pdf `dimension` / `aspect_ratio` analysis, we had to make a breaking change:
- To analyze PDFs, you must install the `poppler` PDF processing dependency
  - It's a  Rails-supported PDF processing dependency (https://guides.rubyonrails.org/active_storage_overview.html#requirements)
  - To install it, check their documentation at this [link](https://pdf2image.readthedocs.io/en/latest/installation.html).
  - To check if it's installed, execute `pdftoppm -h`.
  - To install this tool in your CI / production environments, you can check how we do it in our own CI (https://github.com/igorkasyanchuk/active_storage_validations/blob/master/.github/workflows/main.yml)

We also added the `pages` validator to validate pdf number of pages, and the `equal_to` option to `duration`, `size` and `total_size` validators.

Note that, if you do not perform these metadata validations on pdfs, the gem will work the same as in version 2.
