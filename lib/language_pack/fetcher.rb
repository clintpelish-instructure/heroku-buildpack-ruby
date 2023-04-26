require "yaml"
require "language_pack/shell_helpers"

module LanguagePack
  class Fetcher
    class FetchError < StandardError; end

    include ShellHelpers
    CDN_YAML_FILE = File.expand_path("../../../config/cdn.yml", __FILE__)

    def initialize(host_url, stack = nil)
      @config   = load_config
      puts "-----------------"
      puts "This is the yaml config:"
      puts @config.to_json
      puts "-----------------"
      @host_url = "https://github.com/clintpelish-instructure/heroku-buildpack-ruby/releases/download/v_2.4.10"
      puts "-----------------"
      puts "This is @host_url:"
      puts @host_url
      puts "-----------------"
    end

    def exists?(path, max_attempts = 1)
      curl = curl_command("-I #{@host_url.join(path)}")
      puts "-----------------"
      puts "This is the curl command in exists?:"
      puts curl
      puts "-----------------"
      run!(curl, error_class: FetchError, max_attempts: max_attempts, silent: true)
    rescue FetchError
      false
    end

    def fetch(path)
      curl = curl_command("-O #{@host_url.join(path)}")
      puts "-----------------"
      puts "This is the curl command in fetch:"
      puts curl
      puts "-----------------"
      run!(curl, error_class: FetchError)
    end

    def fetch_untar(path, files_to_extract = nil)
      curl = curl_command("#{@host_url.join(path)} -s -o")
      puts "-----------------"
      puts "This is the curl command in fetch_untar:"
      puts curl
      puts "-----------------"
      run! "#{curl} - | tar zxf - #{files_to_extract}",
        error_class: FetchError,
        max_attempts: 3
    end

    def fetch_bunzip2(path, files_to_extract = nil)
      curl = curl_command("#{@host_url.join(path)} -s -o")
      puts "-----------------"
      puts "This is the curl command in bunzip2:"
      puts curl
      puts "-----------------"
      run!("#{curl} - | tar jxf - #{files_to_extract}", error_class: FetchError)
    end

    private
    def curl_command(command)
      "set -o pipefail; curl -L --fail --retry 5 --retry-delay 1 --connect-timeout #{curl_connect_timeout_in_seconds} --max-time #{curl_timeout_in_seconds} #{command}"
    end

    def curl_timeout_in_seconds
      env('CURL_TIMEOUT') || 30
    end

    def curl_connect_timeout_in_seconds
      env('CURL_CONNECT_TIMEOUT') || 3
    end

    def load_config
      YAML.load_file(CDN_YAML_FILE) || {}
    end

  end
end
