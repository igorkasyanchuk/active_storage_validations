BUNDLE_GEMFILE=gemfiles/rails_next.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_6_1_4.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_0.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle
rm *.gem
rm -fr test/dummy/log/*.log
rm -fr test/dummy/tmp/cache
rm -fr test/dummy/tmp/storage
gem build active_storage_validations.gemspec
