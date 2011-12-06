# encoding: utf8
require 'iconv'

module DoubanFm
  module Encoding
    def conv(data, encoding = nil)
      return data if encoding.nil? || encoding =~ /^utf-?8$/i
      Iconv.conv("UTF8//IGNORE", encoding, data)
    end

    module_function :conv
  end
end
