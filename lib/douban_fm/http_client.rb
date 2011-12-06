# encoding: utf8

require 'curb'
require 'fileutils'
require 'digest/md5'
require 'cgi'

module DoubanFm
  class HttpClient

    class Request

      attr_accessor :method, :useragent, :verbose

      attr_accessor :url, :headers, :cookies, :start_pos

      attr_accessor :use_cache
      
      attr_accessor :follow_location, :max_redirects

      attr_accessor :on_progress, :on_body

      def initialize(url, headers = {})
        @url, @headers = url, headers
        @method = "GET"
        @follow_location = false
        @max_redirects = 0
        @verbose = !! ENV["CURL_VERBOSE"]
      end

      def useragent
        @useragent ||= self.class.default_useragent
      end

      def start_pos=(pos)
        @start_pos = pos
        @headers["Range"] = "bytes=#{pos}-"
      end

      def partial?
        ! start_pos.nil?
      end

      def use_cache?
        !! use_cache
      end

      def self.default_useragent
        @@default_useragent
      end

      def self.default_useragent=(useragent)
        @@default_useragent = useragent
      end

      @@default_useragent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) " +
        "AppleWebKit/535.2 (KHTML, like Gecko) " +
        "Chrome/15.0.874.121 Safari/535.2"
    end

    class Response

      attr_reader :code, :headers, :body

      attr_accessor :request

      alias :data :body

      #Content-Range: bytes 1701910-4932324/4932325
      
      def initialize(code, header_str, body)
        @code, @header_str, @body = code, header_str, body
      end

      def headers
        @headers ||= parse_header_str
      end

      def partial_data?
        code == 206
      end

      def cookies
        @cookies ||=
          begin
            Array(headers["Set-Cookie"]).inject({}) do |memo, line|
              k, v = line.scan(/^([^=])=([^;])/).first
              memo[k] = v if k
              memo
            end
          end
      end

      private

      def parse_header_str
        headers = {}
        return headers if @header_str.nil? 
        @header_str.split(/\r?\n/).each do |line|
          if (line =~ /^([\w_-]+):\s*(.*)$/)
            key, value = $1, $2
            if v = headers[key]
              headers[key] = [v, value].flatten
            else
              headers[key] = value
            end
          end
        end
        headers
      end

    end

    def cache_dir
      self.class.cache_dir
    end

    def get(request)
      return get_without_cache(request) unless request.use_cache?

      self.class.with_cache(request.url) do
        get_without_cache(request)
      end
    end

    def get_without_cache(request)
      c = build_curl(request)
      c.perform

      build_response(request, c)
    end

    def post(url, fields = {})
      request = Request.new(url)
      request.method = "POST"

      c = build_curl(request)
      c.enable_cookies = true

      post_data = fields.inject([]) do |memo, (k, v)|
        memo << "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
      end
      c.http_post(*post_data)

      build_response(request, c)
    end

    private
    def build_curl(request)
      c = Curl::Easy.new(request.url)
      c.verbose = request.verbose

      c.useragent = request.useragent
      c.cookies = request.cookies if request.cookies

      c.follow_location = request.follow_location
      c.max_redirects = request.max_redirects

      request.headers.each do |k, v|
        c.headers[k.to_s] = v
      end if request.headers

      c.on_body = request.on_body if request.on_body
      c.on_progress = request.on_progress if request.on_progress

      c
    end

    def build_response(request, curl)
      response = Response.new(curl.response_code, curl.header_str, curl.body_str)
      response.request = request
      response
    end

    public
    class << self
      def cache_dir=(dir)
        FileUtils.mkdir_p(dir)
        @@cache_dir = dir
      end

      def cache_dir
        @@cache_dir ||= Dir.tmpdir
      end

      def with_cache(url, &block)
        md5 = Digest::MD5.new.hexdigest(url)
        file = File.join(cache_dir, md5)
        return Marshal.load(File.read(file)) if File.exists?(file)

        response = yield
        open(file, "wb") {|f| 
          f.write Marshal.dump(response)
        }
        response
      end

      def get(url, headers = {}, use_cache = false)
        request = Request.new(url, headers)
        request.use_cache = use_cache
        client = HttpClient.new
        response = client.get(request)
        response.data
      end

      def post(url, fields = {})
        client = HttpClient.new
        client.post(url, fields)
      end

    end

  end
end
