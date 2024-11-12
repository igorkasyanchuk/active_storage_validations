# This module sole purpose is to ensure in our tests that we do not override
# the client defined concerns with the gem concerns. Be sure that this concern
# and its method are defined in the gem for the test to work properly.
module Attachable
  extend ActiveSupport::Concern

  def attachable_filename(attachable)
    "client's concern method returned value"
  end
end
