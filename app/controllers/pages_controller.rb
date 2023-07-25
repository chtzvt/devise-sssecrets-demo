class PagesController < ApplicationController
    def home
        # Generate a friendly token with the default prefix 'dv' and sssecrets type 'default'
        @token_with_default_prefix = Devise.friendly_token

        # Generate a friendly token with the 'org' of 'test' and type of 'user'
        @token_with_user_prefix = Devise.friendly_token(org: "test", type: :user)

        # Generate a friendly token with the default 'org' and type of 'admin'
        @token_with_admin_prefix = Devise.friendly_token(type: :admin)
    end
end
  