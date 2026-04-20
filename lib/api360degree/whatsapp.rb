require 'faraday' unless defined?(Faraday)

module Api360degree
  #
  # WhatsApp wrapper
  #
  # == How to use
  #
  # w = Api360degree::WhatsApp.new(MY_API_KEY)
  # w.send_whats_app("phone_number",
  #                  {"body" => ["Customer Name"]},
  #                  new_order",
  #                  "es",
  #                  "MY_NAMESPACE")
  #
  class WhatsApp
    attr_reader :api_key

    # The endpoints
    API_CONTACT_ENDPOINT = 'https://waba.360dialog.io/v1/contacts'
    API_MESSAGES_ENDPOINT = 'https://waba.360dialog.io/v1/messages'

    API_CONTACT_ENDPOINT_V2 = 'https://waba-v2.360dialog.io/contacts'
    API_MESSAGES_ENDPOINT_V2 = 'https://waba-v2.360dialog.io/messages'
    API_MEDIA_ENDPOINT_V2 = 'https://waba-v2.360dialog.io/media'

    #
    # Constructor
    #
    # == Arguments::
    #
    # api_key:: [String] The API Key
    #
    def initialize(api_key)
      @api_key = api_key
    end

    #
    # Send a Whatsapp using 360 degree
    #
    # == Parameters::
    #
    # to:: [String] Phone number
    # place_holders:: [Hash] of Arrays with place holders
    #
    #    {header: ["Customer Name"],
    #     body: ["Order Number"]}
    #
    # template:: [String] template name
    # language:: [String] ISO Code language
    # namespace:: [String] The namespace
    #
    # == Returns::
    #
    # [Hash] the response body
    #
    # == Throws::
    #
    # [WhatsAppException] if error calling API
    #
    def send_whatsapp(to,
                      placeholders,
                      template,
                      language,
                      namespace,
                      version=:v2)

      case version
      when :v1
        send_whatsapp_v1(to, placeholders, template, language, namespace)
      when :v2
        send_whatsapp_v2(to, placeholders, template, language, namespace)
      else
        raise WhatsAppException.new("Version #{version} not supported")
      end

    end

    #
    # Upload a media file to 360dialog (v2)
    #
    # The file is uploaded and a media_id is returned that can be used
    # in send_document, send_image, etc.
    #
    # == Parameters::
    #
    # file_path:: [String] Path to the file
    # mime_type:: [String] MIME type (e.g. 'application/pdf', 'image/jpeg')
    #
    # == Returns::
    #
    # [String] The media_id
    #
    # == Throws::
    #
    # [WhatsAppException] if error calling API
    #
    def upload_media(file_path, mime_type)
      raise WhatsAppException.new("File not found: #{file_path}", nil) unless File.exist?(file_path)

      conn = Faraday.new(API_MEDIA_ENDPOINT_V2) do |f|
        f.request :multipart
        f.adapter Faraday.default_adapter
      end

      response = conn.post do |req|
        req.headers['D360-API-KEY'] = @api_key
        req.body = {
          'messaging_product' => 'whatsapp',
          'type' => mime_type,
          'file' => Faraday::Multipart::FilePart.new(file_path, mime_type, File.basename(file_path))
        }
      end

      raise WhatsAppException.new("Error uploading media: #{response.status}",
                                  response.body) unless response.status == 200 || response.status == 201

      result = JSON.parse(response.body)
      result['id']
    end

    #
    # Send a document message via 360dialog (v2)
    #
    # == Parameters::
    #
    # to:: [String] Phone number
    # media_id:: [String] Media ID obtained from upload_media
    # filename:: [String] Filename to display to the recipient
    # caption:: [String, nil] Optional caption text
    #
    # == Returns::
    #
    # [Array] [success_boolean, response_hash]
    #
    # == Throws::
    #
    # [WhatsAppException] if error calling API
    #
    def send_document(to, media_id, filename, caption = nil)
      document = { 'id' => media_id, 'filename' => filename }
      document['caption'] = caption if caption
      send_media_message(to, 'document', document)
    end

    #
    # Send an image message via 360dialog (v2)
    #
    # == Parameters::
    #
    # to:: [String] Phone number
    # media_id:: [String] Media ID obtained from upload_media
    # caption:: [String, nil] Optional caption text
    #
    # == Returns::
    #
    # [Array] [success_boolean, response_hash]
    #
    # == Throws::
    #
    # [WhatsAppException] if error calling API
    #
    def send_image(to, media_id, caption = nil)
      image = { 'id' => media_id }
      image['caption'] = caption if caption
      send_media_message(to, 'image', image)
    end

    private

    #
    # Send a media message via 360dialog (v2)
    #
    # == Parameters::
    #
    # to:: [String] Phone number
    # media_type:: [String] Type: 'document', 'image', 'video', 'audio'
    # media_payload:: [Hash] Media-specific payload (id, filename, caption, etc.)
    #
    # == Returns::
    #
    # [Array] [success_boolean, response_hash]
    #
    def send_media_message(to, media_type, media_payload)
      payload = {
        'messaging_product' => 'whatsapp',
        'recipient_type' => 'individual',
        'to' => to,
        'type' => media_type,
        media_type => media_payload
      }

      conn = Faraday.new(API_MESSAGES_ENDPOINT_V2)

      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['D360-API-KEY'] = @api_key
        req.body = payload.to_json
      end

      raise WhatsAppException.new("Error sending #{media_type} to #{to}",
                                  response.body) unless response.status == 200 || response.status == 201

      [true, JSON.parse(response.body)]
    end

    #
    # Send a Whatsapp using 360 degree V1
    #
    def send_whatsapp_v1(to,
                         placeholders,
                         template,
                         language,
                         namespace)

      # = Check contact
      self.check_contact(to)

      # = Build payload

      components = build_parameters(placeholders)

      payload = {
            "to" => to,
            "type" => "template",
            "template" => {
                "namespace" => namespace,
                "language" => {
                    "policy" => "deterministic",
                    "code" => language
                },
                "name" => template,
                "components" => components
            }
      }

      # = Send the message

      # - Create Faraday instance
      conn = Faraday.new(API_MESSAGES_ENDPOINT)

      # - Make a post the the connection
      response = conn.post do |req|
            req.headers['Content-Type'] = 'application/json'
            req.headers['D360-API-KEY'] = @api_key
            req.body = payload.to_json
      end

      # - Check response (400 is a error with a errors in hash)
      raise WhatsAppException.new("Error sending message to #{to}",
                                  response.body) unless response.status == 200 or response.status == 201 or response.status == 400

      [(response.status == 200 or response.status == 201), JSON.parse(response.body)]
    end

    #
    # Send a Whatsapp using 360 degree V2
    #
    def send_whatsapp_v2(to,
                         placeholders,
                         template,
                         language,
                         namespace)

      # = Build payload

      components = build_parameters(placeholders)

      payload = {
            "messaging_product": "whatsapp",
            "recipient_type": "individual",
            "to" => to,
            "type" => "template",
            "template" => {
                "namespace" => namespace,
                "language" => {
                    "policy" => "deterministic",
                    "code" => language
                },
                "name" => template,
                "components" => components
            }
      }

      p "payload: #{payload.inspect}"

      # = Send the message

      # - Create Faraday instance
      conn = Faraday.new(API_MESSAGES_ENDPOINT_V2)

      # - Make a post the the connection
      response = conn.post do |req|
            req.headers['Content-Type'] = 'application/json'
            req.headers['D360-API-KEY'] = @api_key
            req.body = payload.to_json
      end

      # - Check response (400 is a error with a errors in hash)
      raise WhatsAppException.new("Error sending message to #{to}",
                                  response.body) unless response.status == 200 or response.status == 201 or response.status == 400

      [(response.status == 200 or response.status == 201), JSON.parse(response.body)]

    end

    #
    # Check the contact
    #
    # == Parameters::
    #
    # contact:: [String] the phone number
    #
    # == Returns::
    #
    # [Hash] the response body
    #
    # == Throws::
    #
    # [WhatsAppException] if error calling API
    #
    def check_contact(contact)

      # == Build payload
      payload = {
                  "blocking" => "wait",
                  "contacts" => ["+#{contact}"],
                  "force_check" => true
                }

      # = Send the message

      # - Create Faraday instance
      conn = Faraday.new(API_CONTACT_ENDPOINT)

      # - Make a post the the connection
      response = conn.post do |req|
            req.headers['Content-Type'] = 'application/json'
            req.headers['D360-API-KEY'] = @api_key
            req.body = payload.to_json
      end


      # - Process response
      raise WhatsAppException.new("Error checking contact #{contact} #{response.status}",
                                  response.body) unless response.status == 200 or response.status == 201

      # Return the response body
      response.body

    end

    #
    # Build parameters for a message
    #
    # == Parameters::
    #
    # placeholders:: [Hash]
    #
    # == Example (text header)
    #
    #    {header: ["Customer Name"],
    #     body: ["Order Number"]}
    #
    # == Example (document header)
    #
    #    {header: { type: 'document', document: { id: 'media_id', filename: 'factura.pdf' } },
    #     body: ["Customer Name", "F-2026-001"]}
    #
    # == Example (image header)
    #
    #    {header: { type: 'image', image: { id: 'media_id' } },
    #     body: ["Customer Name"]}
    #
    # == Returns::
    #
    # [Array] of [Hash] with the parameters adapted
    #
    def build_parameters(placeholders)

      # - Prepare the parameters
      components = []

      # - Header parameters
      if placeholders.has_key?(:header)
        header = placeholders[:header]
        if header.is_a?(Hash) && header.has_key?(:type)
          # Media header (document, image, video)
          media_type = header[:type]
          parameter = { 'type' => media_type }
          parameter[media_type] = header[media_type.to_sym] if header.has_key?(media_type.to_sym)
          components << {
                          "type" => "header",
                          "parameters" => [parameter]
                        }
        elsif header.is_a?(Array)
          # Text header (backwards compatible)
          components << {
                          "type" => "header",
                          "parameters" => header.map { |placeholder| {type: 'text', text: placeholder.to_s} }
                        }
        end
      end
      # - Body parameters
      if placeholders.has_key?(:body) and placeholders[:body].is_a?(Array)
        components << {
                        "type" => "body",
                        "parameters" => placeholders[:body].map { |placeholder| {type: 'text', text: placeholder.to_s} }
                      }
      end
      # - Footer parameters
      if placeholders.has_key?(:footer) and placeholders[:footer].is_a?(Array)
        components << {
                        "type" => "footer",
                        "parameters" => placeholders[:footer].map { |placeholder| {type: 'text', text: placeholder.to_s} }
                      }
      end

      # - Buttons
      if placeholders.has_key?(:buttons) and placeholders[:buttons].is_a?(Hash)
        placeholders[:buttons].each do |key, value|
          next unless value.has_key?(:sub_type) and ['url','quick_reply'].include?(value[:sub_type])
          next unless value.has_key?(:parameters) and value[:parameters].is_a?(Array)
          components << {
                          "type" => "button",
                          "sub_type" => value[:sub_type],
                          "index" => key,
                          "parameters" => value[:parameters].map { |placeholder| {type: 'text', text: placeholder.to_s} }
                        }
        end
      end

      components

    end


  end
end
