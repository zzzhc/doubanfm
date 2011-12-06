require 'logger'

module DoubanFm

  autoload :HttpClient, 'douban_fm/http_client'
  autoload :Encoding  , 'douban_fm/encoding'
  autoload :Song      , 'douban_fm/song'
  autoload :User      , 'douban_fm/user'
  autoload :Utils     , 'douban_fm/utils'
  autoload :Provider  , 'douban_fm/provider'
  autoload :Cli       , 'douban_fm/cli'

  def self.logger
    @logger ||= Logger.new(STDERR)
  end

end

