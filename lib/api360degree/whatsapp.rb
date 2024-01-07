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
      conn = Faraday.new(API_MESSAGES_ENDPOINT)# do |faraday|
              # faraday.response :json
             #end

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
      raise WhatsAppException.new("Error checking contact #{contact}",
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
    # == Example
    #
    #    {header: ["Customer Name"],
    #     body: ["Order Number"]}
    #
    # == Returns::
    #
    # [Array] of [Hash] with the parameters adapted
    #
    def build_parameters(placeholders)

      # - Prepare the parameters
      components = []

      # - Header parameters
      if placeholders.has_key?(:header) and placeholders[:header].is_a?(Array)
        components << {
                        "type" => "header",
                        "parameters" => placeholders[:header].map { |placeholder| {type: 'text', text: placeholder.to_s} }
                      }
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
