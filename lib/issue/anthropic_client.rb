# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Issue
  module AnthropicClient
    API_URL = 'https://api.anthropic.com/v1/messages'
    API_VERSION = '2023-06-01'
    DEFAULT_MODEL = 'claude-haiku-4-5'
    MAX_TOKENS = 1024
    DEFAULT_PROMPT = <<~PROMPT
      A partir del siguiente texto, genera un issue para un equipo de desarrollo.

      Texto:
      {{description}}

      Responde SOLO JSON valido, sin markdown ni texto extra, con esta forma exacta:
      {"title":"...","description":"..."}

      Reglas:
      - title: maximo 72 caracteres, claro y especifico
      - description: un parrafo bien redactado que explique el problema o la tarea
      - Escribe en espanol estandar, sin regionalismos
      - No uses markdown en la descripcion, solo texto plano
    PROMPT

    module_function

    def build_prompt(description)
      template = Config.prompt || DEFAULT_PROMPT
      template.gsub('{{description}}', description)
    end

    def extract_title_description(hash)
      return nil unless hash.is_a?(Hash)

      title = hash['title'].to_s
      description = hash['description'].to_s
      return nil if Helpers.blank?(title) || Helpers.blank?(description)

      [title, description]
    end

    def normalize_model_output(text)
      cleaned = text.to_s.strip
      cleaned = cleaned.sub(/^```(?:json)?\s*/i, '').sub(/\s*```$/, '')

      parsed = extract_title_description(Helpers.parse_json(cleaned))
      return parsed if parsed

      patched = cleaned.gsub(/\\n(?=\s*")/, "\n").gsub(/\\n(?=\s*\})/, "\n")
      parsed = extract_title_description(Helpers.parse_json(patched))
      return parsed if parsed

      title_match = cleaned.match(/"title"\s*:\s*"((?:\\.|[^"\\])*)"/m)
      description_match = cleaned.match(/"description"\s*:\s*"((?:\\.|[^"\\])*)"/m)
      return nil unless title_match && description_match

      title = Helpers.decode_json_string(title_match[1]).to_s
      description = Helpers.decode_json_string(description_match[1]).to_s
      return nil if Helpers.blank?(title) || Helpers.blank?(description)

      [title, description]
    end

    def call(description, api_key:)
      uri = URI(API_URL)
      request = Net::HTTP::Post.new(uri)
      request['x-api-key'] = api_key
      request['anthropic-version'] = API_VERSION
      request['content-type'] = 'application/json'
      request.body = JSON.generate(
        model: Config.model || DEFAULT_MODEL,
        max_tokens: MAX_TOKENS,
        messages: [{ role: 'user', content: build_prompt(description) }]
      )

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        warn "Error: Anthropic API returned HTTP #{response.code}."
        warn response.body
        exit 1
      end

      data = Helpers.parse_json(response.body)
      unless data
        warn 'Error: invalid response from Anthropic.'
        exit 1
      end

      assistant_text = (data.dig('content', 0, 'text') || '').strip
      if Helpers.blank?(assistant_text)
        warn 'Error: no text response received from Anthropic.'
        exit 1
      end

      result = normalize_model_output(assistant_text)
      unless result
        warn 'Warning: could not parse JSON from Anthropic; using original description.'
        result = [
          description.strip.gsub(/\s+/, ' ')[0, 72],
          description
        ]
      end

      result
    end
  end
end
