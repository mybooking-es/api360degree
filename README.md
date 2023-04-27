# Api::360degree

## Introduction

The purspose of this gem is to send text based template messages via 360 degrees

Please note that you cannot initiate a freetext message with WhatsappAPI. Instead, you must use a pre-approved template.

It is a Ruby port of https://github.com/chatwithio/php-360degree-template-message-send improved with 
header, footer and buttons parameters.

## Getting a 360degree API Key

You can get one from here: https://tochat.be

## Creating a template

The class support text based messages with header, body, footer parameters and buttons. It does not support images yet.

Thus, you can create a template in 360degree. Once the template has been approved you can start to use the starter pack.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'api-360degree'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install api-360degree

## Usage

In order to use the gem you need an API key, a namespace and template.

```
  whatsapp_client = Api360degree::WhatsApp.new(MY_API_KEY)
  whatsapp_client.send_whats_app("phone_number",
                                 {"body" => ["Customer Name"],
                                 "new_order",
                                 "es",
                                 "MY_NAME_SPACE")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/api-360degree.
