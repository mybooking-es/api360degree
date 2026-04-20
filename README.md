# Api360degree WhatsApp

## Introduction

The purpose of this gem is to send WhatsApp messages via 360 Dialog API (v2).

Supports:
- **Template messages** with text, document, image and video headers
- **Media upload** (documents, images) for use in templates or direct messages
- **Direct document/image sending** within the 24h conversation window

Please note that you cannot initiate a freetext message with WhatsApp API. Instead, you must use a pre-approved template. Direct media messages can only be sent within an active 24h conversation window.

It is a Ruby port of https://github.com/chatwithio/php-360degree-template-message-send improved with
header, footer, buttons and media support.

You can get full documentation from the following sources:

- https://docs.360dialog.com/docs/whatsapp-api/onboarding-guide-summary
- https://developers.facebook.com/docs/whatsapp/api/messages/message-templates/interactive-message-templates
- https://developers.facebook.com/docs/whatsapp/cloud-api/guides/send-messages#media-messages

## Getting a 360degree API Key

You can get one from here: https://tochat.be

## Creating a template

You can create templates with text, document, image or video headers in 360dialog.
Once the template has been approved you can start using it.

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

### Sending a text template

```ruby
w = Api360degree::WhatsApp.new(MY_API_KEY)
w.send_whatsapp(
  '34612345678',
  { header: ['Customer Name'],
    body: ['Order Number'] },
  'new_order',
  'es',
  'MY_NAMESPACE'
)
```

### Sending a template with a document (e.g. invoice PDF)

Requires a template approved by Meta with a header of type `document`.

```ruby
w = Api360degree::WhatsApp.new(MY_API_KEY)

# 1. Upload the document
media_id = w.upload_media('/path/to/invoice.pdf', 'application/pdf')

# 2. Send the template with the document as header
w.send_whatsapp(
  '34612345678',
  { header: { type: 'document', document: { id: media_id, filename: 'invoice.pdf' } },
    body: ['Juan Garcia', 'F-2026-001'] },
  'send_invoice',
  'es',
  'MY_NAMESPACE'
)
```

### Sending a template with an image

Requires a template approved by Meta with a header of type `image`.

```ruby
w = Api360degree::WhatsApp.new(MY_API_KEY)

media_id = w.upload_media('/path/to/photo.jpg', 'image/jpeg')

w.send_whatsapp(
  '34612345678',
  { header: { type: 'image', image: { id: media_id } },
    body: ['Customer Name'] },
  'welcome_with_photo',
  'es',
  'MY_NAMESPACE'
)
```

### Sending a document directly (within 24h window)

When the conversation window is open (customer has written in the last 24h), you can send documents without a template.

```ruby
w = Api360degree::WhatsApp.new(MY_API_KEY)

media_id = w.upload_media('/path/to/contract.pdf', 'application/pdf')
w.send_document('34612345678', media_id, 'contract.pdf', 'Your signed contract')
```

### Sending an image directly (within 24h window)

```ruby
w = Api360degree::WhatsApp.new(MY_API_KEY)

media_id = w.upload_media('/path/to/photo.jpg', 'image/jpeg')
w.send_image('34612345678', media_id, 'Photo caption')
```

### Sending from binary content (e.g. generated PDF)

When the content is in memory (not a file on disk), use a `Tempfile`:

```ruby
w = Api360degree::WhatsApp.new(MY_API_KEY)

tmp = Tempfile.new(['invoice', '.pdf'])
tmp.binmode
tmp.write(pdf_content)
tmp.flush
tmp.close

media_id = w.upload_media(tmp.path, 'application/pdf')
w.send_document('34612345678', media_id, 'invoice.pdf', 'Your invoice')
ensure
  tmp&.unlink
```

## API Reference

### `WhatsApp.new(api_key)`

Creates a new client instance.

### `send_whatsapp(to, placeholders, template, language, namespace, version = :v2)`

Sends a template message. The `placeholders` hash supports:

| Key | Type | Description |
|-----|------|-------------|
| `:header` | `Array` | Text header placeholders (e.g. `['Customer Name']`) |
| `:header` | `Hash` | Media header: `{ type: 'document'\|'image'\|'video', <type>: { id: media_id, ... } }` |
| `:body` | `Array` | Body text placeholders |
| `:footer` | `Array` | Footer text placeholders |
| `:buttons` | `Hash` | Button parameters (`quick_reply`, `url`) |

### `upload_media(file_path, mime_type)`

Uploads a file and returns a `media_id` string.

### `send_document(to, media_id, filename, caption = nil)`

Sends a document message directly (requires open 24h window).

### `send_image(to, media_id, caption = nil)`

Sends an image message directly (requires open 24h window).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mybooking-es/api360degree.
