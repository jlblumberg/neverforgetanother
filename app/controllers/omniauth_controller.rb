class OmniauthController < ApplicationController
  # OmniAuth middleware intercepts POST /auth/:provider before this is called
  # This action exists only for routing purposes
  def passthru
    head :not_found
  end
end
