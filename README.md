# OpsmanagerClient::Client

DSL for Pivotal Ops Manager

## Installation

Add this line to your application's Gemfile:

    gem 'opsmanager_client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install opsmanager_client

## Usage

```sh
cat opsmanager_config.json
{
  "tempest": {
    "url": "https://10.0.0.1",
    "username": "username",
    "password": "password"
  }
}
export TEMPEST_CONFIG_FILE_PATH=$PWD/opsmanager_config.json
```

```ruby
product = OpsmanagerClient::Product.new("~/Downloads/p-cassandra-0.1.147.pivotal")

OpsmanagerClient::Client.product_uploaded?(product)
OpsmanagerClient::Client.upload_product(product)

OpsmanagerClient::Client.available_products
OpsmanagerClient::Client.delete_unused_products

OpsmanagerClient::Client.cf_admin_credentials
```

## Terminology

### Adding products

A1. **Add** (the equivalent of uploading the .pivotal file)

A2. **Install** (the equivalent of clicking the "Add" button for that product)

A3. Configure

A4. **Deploy** (the equivalent of "Apply changes")


### Removing products

R1. **Uninstall** (the equivalent of "Remove tile" & "Apply changes" - inverse of A4, A3 & A2)

R2. **Remove** (no UI equivalent, equivalent to removing from list of available products - inverse of A1)

## Contributing

1. Fork it ( https://github.com/[my-github-username]/tempest-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
