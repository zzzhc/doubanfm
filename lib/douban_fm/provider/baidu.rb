require 'fileutils'
require 'douban_fm/utils'

module DoubanFm
  module Provider
    class Baidu

      CHARSET = "GB18030"

      def initialize(dir)
        FileUtils.mkdir_p(dir)
        @dir = dir
      end

      def logger
        DoubanFm.logger
      end

      def download(song, &block)
        query_list = [
          "#{song.title} #{song.artist} #{song.album}",
          "#{song.title} #{song.artist}",
          "#{song.title}",
        ]
        query_list.each do |query|
          links = find_download_links(song, query)
          next if links.size == 0
          link = links.first
          download_mp3(song, link, &block)
          return true
        end
      rescue Exception => e
        logger.debug "download failed: #{e.message}"
        return false
      end

      private
      def normalize_query(query)
        query = Iconv.conv(CHARSET, "UTF8", query)
        query = CGI.escape(query)
      end

      def find_download_links(song, query)
        query = normalize_query(query)
        url = "http://mp3.baidu.com/m?word=#{query}&lm=0"

        doc = Utils.get_document(url, :encoding => CHARSET, :use_cache => false)

        doc.css(".table-song-list td.second > a").map {|e| e["href"]}.select do |link|
          link !~ /box.zhangmen.baidu.com/
        end
      end

      def mp3_link(link)
        doc = Utils.get_document(link, :encoding => CHARSET, :use_cache => false)
        mp3_link = doc.at_css("#downlink, #urla")["href"]

        if mp3_link =~ /^\/j.*&url=(.+)$/i
          mp3_link = CGI.unescape($1)
          #mp3_link = "http://mp3.baidu.com#{mp3_link}"
        end

        mp3_link
      end

      def download_mp3(song, link, &block)
        logger.debug "download from #{link}"
        url = mp3_link(link)

        name = song.to_mp3_name
        file = File.join(@dir, name)

        Curl::Easy.download(url, file) do |curl|
          curl.follow_location = true
          curl.autoreferer = true

          curl.on_progress do |*args|
            block.call(*args)
          end
        end
      end

    end
  end
end
