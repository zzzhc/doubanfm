# encoding: utf8

require 'set'
require 'uri'

module DoubanFm

  class User

    def initialize(cookie)
      @cookie = cookie
    end

    def liked_song_list
      song_list = []
      visited_links = Set.new

      start_url = "http://douban.fm/mine?start=0&type=liked"
      uri = URI.parse(start_url)
      queue = [uri]
      while queue.size > 0
        uri = queue.shift
        unless visited_links.include?(uri)
          DoubanFm.logger.debug "get #{uri.to_s}"
          visited_links << uri

          doc = Utils.get_document(uri.to_s, :use_cache => true, :cookies => @cookie)
          songs = find_songs(doc)
          song_list.concat songs

          doc.css(".paginator a").each do |a|
            uri = URI.join("http://douban.fm/mine?start=0&type=liked", a["href"])
            queue << uri unless visited_links.include?(uri)
          end
        end
      end

      song_list
    end

    def find_songs(doc)
      songs = doc.css("#record_viewer .song_info")
      songs.map do |e|
        title = e.at_css(".song_title").content.strip
        artist = e.at_css(".performer").content.strip
        album = e.at_css(".source").content.strip
        Song.new(title, artist, album)
      end
    end

  end

end
