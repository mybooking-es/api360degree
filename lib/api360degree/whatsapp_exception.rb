module Api360degree
  #
  # WhatsApp custom Exception
  #
  class WhatsAppException < StandardError
    
    attr_reader :response_body
    
    # 
    # Constructor
    #
    # == Parameters::
    #
    # message:: [String] The exception message
    # response_body:: [Hash] The API call response body
    #
    def initialize(message, response_body)
      super(message)
      @response_body = response_body
    end

  end
end