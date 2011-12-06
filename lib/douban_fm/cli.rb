# encoding: utf8

require 'optparse'
require 'progressbar'

module DoubanFm
  class Cli

    def initialize(options)
      @options = options
      @download_dir = "./download"
    end

    def run
      parse_options
      DoubanFm.logger.level = Logger::DEBUG if @verbose
      cache_dir = File.expand_path("cache", @download_dir)
      FileUtils.rm_rf(cache_dir) if @flush_cache
      HttpClient.cache_dir = cache_dir

      quit = false
      trap("INT") do
        quit = true
      end

      user = DoubanFm::User.new(@cookie)
      provider = DoubanFm::Provider::Baidu.new(@download_dir)
      songs = user.liked_song_list
      songs.each_with_index do |song, index|
        puts "下载 #{song.artist} #{song.album} #{song.title}"

        progressbar = ProgressBar.new("#{index + 1}/#{songs.size}", 1)
        provider.download(song) do |dl_total, dl_now, ul_total, ul_now|
          progress = dl_total > 0 ? dl_now / dl_total : 0
          progressbar.set(progress)
          !quit
        end
        quit ? progressbar.halt : progressbar.finish

        break if quit
      end
    end

    private
    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"
        opts.on("-d dir", "下载目录，缺省为./download") do |dir|
          @download_dir = dir
        end
        opts.on("-c cookie", "douban.fm cookie, 必须有") do |cookie|
          @cookie = cookie
        end
        opts.on("-v", "--verbose", "输出调试信息") do
          @verbose = true
        end
        opts.on("-f", "--flush-cache", "清空歌曲列表缓存") do
          @flush_cache = true
        end
        opts.on("-h", "--help", "显示帮助") do
          show_help
        end
      end
    end

    def parse_options
      parser.parse!(@options)
      show_help if @cookie.nil?
    rescue OptionParser::ParseError => e
      show_help
    end

    def show_help
      puts @parser
      exit -1
    end
  end
end
