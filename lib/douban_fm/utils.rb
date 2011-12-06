# encoding: utf8

require 'nokogiri'

module DoubanFm
  module Utils

    def get_document(url, options = {})
      encoding = options[:encoding]
      use_cache = options[:use_cache]

      headers = {}
      if cookies = options[:cookies]
        headers["Cookie"] = cookies
      end

      body = HttpClient.get(url, headers, use_cache)
      body = Encoding.conv(body, encoding)
      Nokogiri::HTML(body)
    end

    module_function :get_document
  end
end
