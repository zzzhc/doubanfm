# encoding: utf8

module DoubanFm
  class Song

    attr_accessor :title, :artist, :album

    def initialize(title, artist = nil, album = nil)
      @title, @artist, @album = title, artist, album
    end

    def to_mp3_name
      "#{artist}-#{album}-#{title}.mp3".gsub(/\//, " ").gsub(/\s+/, ' ')
    end

  end
end
