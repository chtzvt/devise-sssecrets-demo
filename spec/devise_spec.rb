require 'rails_helper'
require 'devise'
require 'sssecrets'

describe Devise do
  describe '.friendly_token' do
    it 'generates a valid sssecret friendly token' do
      friendly_token = Devise.friendly_token
      expect(friendly_token).to be_a(String)
      expect(friendly_token).to match(/\A\w{2,10}_\w{36}\z/)
    end

    it 'generates a unique sssecret token for each call' do
      token1 = Devise.friendly_token
      token2 = Devise.friendly_token
      expect(token1).not_to eq(token2)
    end

    it 'generates a sssecret that passes validation' do
      friendly_token = Devise.friendly_token
      expect(SimpleStructuredSecrets.new("", "").validate(friendly_token)).to be_truthy
    end
  end
end
