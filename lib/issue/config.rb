# frozen_string_literal: true

require 'yaml'

module Issue
  module Config
    CONFIG_PATH = File.join(Dir.home, '.config', 'issue', 'config.yaml')

    module_function

    def data
      @data ||= load_file
    end

    def prompt  = data['prompt']
    def model   = data['model']
    def team    = data['team']

    def load_file
      return {} unless File.exist?(CONFIG_PATH)

      result = YAML.safe_load_file(CONFIG_PATH) || {}
      result.is_a?(Hash) ? result : {}
    rescue Psych::SyntaxError => e
      warn "Warning: invalid config.yaml: #{e.message}"
      {}
    end
  end
end
