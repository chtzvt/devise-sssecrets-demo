# Sssecrets Demo - Devise Custom Friendly Token Generator

## Purpose

[Sssecrets](https://github.com/chtzvt/sssecrets) is a handy gem for generating secure tokens that are easy for static analysis tools to identify. It works great as a standalone tool, but there are cases where developers may want to integrate it with authentication frameworks like [Devise](https://github.com/heartcombo/devise). 

This example provides a demonstration of how to use sssecrets with Devise as a drop-in replacement for the framework's [built-in friendly token generator](https://github.com/heartcombo/devise/blob/main/lib/devise.rb#L507). By introducing the use of sssecrets for token generation and enabling the configuration of token prefixes and organizations, developers can generate secure and unique tokens with consistent, configurable, identifiable prefixes to suit various use cases.

To learn more about the sssecrets gem and the case for using structured secrets in your application, check out the [Sssecrets repository](https://github.com/chtzvt/sssecrets).

## Why Structured Secrets?

If you're a developer and your application issues some kind of access tokens (API keys, PATs, etc), it's important to format these in a way that both identifies the string as a secret token and provides insight into its permissions.

[Simple Structured Secrets](https://github.com/chtzvt/sssecrets) help solve this problem: They're a compact format with properties that are optimized for detection with static analysis tools. That makes it possible to automatically detect when secrets are leaked in a codebase using features like [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning) or GitLab Secret Detection.

Here's an example. HashiCorp Vault's API access tokens look like this ([ref](https://developer.hashicorp.com/vault/api-docs#authentication)):

`f3b09679-3001-009d-2b80-9c306ab81aa6`

You might think that this is pretty is a pretty easy pattern to search for, but here's the issue: It's just a [UUID string](https://en.wikipedia.org/wiki/Universally_unique_identifier).

While random, strings in this format are used in many places for non-sensitive purposes. Meaning that, given a random UUID formatted string, it's impossible to know whether it's a sensitive API credential or a garden-variety identifier for something mundane. In cases like these, secret scanning can't help much.

## Implementation

The modifications are implemented in the Devise initializer file located at `config/initializers/devise.rb`. This initializer allows you to configure multiple token prefixes and an organization for the friendly token generator.

### Prefix Configuration

Token prefixes are a simple and effective method to make tokens identifiable. [Slack](https://api.slack.com/authentication/token-types), [Stripe](https://stripe.com/docs/api/authentication), [GitHub](https://github.blog/2021-04-05-behind-githubs-new-authentication-token-formats/#identifiable-prefixes), and others have adopted this approach to great effect. 

Sssecrets allows you to provide two abbreviated strings, `org` and `type`, which together make up the token prefix. Generally, `org` would be used to specify an overarching identifier (like your company or app), while `type` is intended to identify the token type (i.e., OAuth tokens, refresh tokens, etc) in some way. To maintain a compact and consistent format for Sssecret tokens, `org` and `type` together should not exceed 10 characters in length.

The overridden `Devise#friendly_token` implementation has been extended to accept two optional parameters:

- `prefix_type`: Specifies the type of the token prefix. If not provided, it defaults to `:default`.

- `org`: Specifies the organization for the friendly token. If not provided, the default organization is used.

_Note: the [original implementation's](https://github.com/heartcombo/devise/blob/main/lib/devise.rb#L507) `length` parameter is now ignored._

## How to Use

Before you begin, add `sssecrets` to your gemfile and install it.

1. Open the Devise initializer file at `config/initializers/devise.rb`.

The following 29 line block is all that's necessary to wire sssecrets up to Devise:

```ruby
require 'sssecrets'

module Devise
  mattr_accessor :friendly_token_types
  mattr_accessor :friendly_token_org

  # Configuration block to set multiple token prefixes with sssecrets types and org
  def self.setup
    self.friendly_token_types = {default: "ft"}
    self.friendly_token_org = "dv" 
    yield(self)
  end

  def self.friendly_token(**kwargs)
    type = kwargs[:type] || :default
    org = kwargs[:org] || friendly_token_org

    generator = SimpleStructuredSecrets.new(org, sssecrets_type_for(type))
    generator.generate()
  end

  private

  def self.sssecrets_type_for(type)
    friendly_token_types[type] || friendly_token_types[:default]
  end
end
```

2. Use the `Devise.setup` block to set up multiple token prefixes and the default organization (optional).

```ruby
Devise.setup do |config|
  config.friendly_token_org = 'dv' # Set your sssecret token organization. Defaults to "dv".
  config.friendly_token_types[:default] = 'ft' # Add your sssecret token types like so. Default is "ft".
  config.friendly_token_types[:user] = 'usr'
  config.friendly_token_types[:admin] = 'adm'

  # Any other Devise configuration...
end
```

3. Call `Devise#friendly_token` with your desired parameters to generate friendly tokens based on the configured sssecrets prefixes and organization.

## Example

```ruby
# Generate a friendly token with the default org 'dv' and default type of 'ft'
token_with_default_prefix = Devise.friendly_token
"dvft_3MU5bK5MChmzOmxCsQIhb7CEXgdcPj3tNmF9"

# Generate a friendly token with the 'org' of 'test' and type of 'user'
token_with_user_prefix = Devise.friendly_token(org: "test", prefix_type: :user)
"testusr_cFl9hMJTxPRxpnHBmiUNgKizhilscT4RfLk2"

# Generate a friendly token with the default 'org' and type of 'admin'
token_with_admin_prefix = Devise.friendly_token(prefix_type: :admin)
"dvadm_2Srrwf5IWVubTHmqBTVmvAraHgeCYO11ezUh"
```

You can run the live example from this repository.

## Tests

Tests are included in this repository: 

```shell
bundle exec rspec spec/devise_spec.rb
```