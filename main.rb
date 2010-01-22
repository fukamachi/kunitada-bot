require 'rubygems'
require 'sinatra'
require 'yaml'
require 'uri'
require 'rexml/document'
require 'twitter'
require 'appengine-apis/urlfetch'

VERB = '動詞'
NOUN = '名詞'
AUXI = '助動詞'
CONJ = '接続助詞'
SURU = '助動詞する'

before do
  @conf = YAML.load_file('config.yaml')
  @twitter = Twitter.new(@conf['user']['username'], @conf['user']['password'])
  @appid = @conf['morphem']['appid']
end

get '/cron/kunitadize' do
  tweets = @twitter.tejimaya_timeline

  return 'ツイートがありませんでした。' if tweets.empty?

  while tweet = tweets.shuffle.shift
    next if tweet =~ /最速で/
    kunitadized = kunitadize(tweet['text'], tweet['user']['screen_name'])
    if tweet['text'] != kunitadized
      @twitter.update(sprintf("@%s が最速で呟いた: %s", tweet['user']['screen_name'], kunitadized), tweet['id'])
      break
    end
  end

  return
end

def kunitadize(sentence, screen_name)
  url = 'http://jlp.yahooapis.jp/DAService/V1/parse'
  url += "?appid=#@appid&sentence=#{URI.escape(sentence)}"
  res = AppEngine::URLFetch.fetch(url)
  doc = REXML::Document.new(res.body)
  saisoku = screen_name == 'kunitada' ? '超最速で' : '最速で'

  text = ''
  chunk_list = []

  doc.elements.each('ResultSet/Result/ChunkList/Chunk') do |chunk|
    morphem_list = []
    chunk.elements.each('MorphemList/Morphem') do |morphem|
      morphem_list.push({
        'surface' => morphem.elements['Surface'].text,
        'feature' => morphem.elements['Feature'].text.split(','),
      })
    end

    if morphem_list.map {|morphem| morphem['feature'][0] }.include? VERB
      should_insert = true
      if (morphem_list[0]['feature'][0] == VERB and
          ((chunk_list[-1][-1]['feature'][0] == VERB) or
           (chunk_list[-1][-1]['feature'][1] == CONJ and
            chunk_list[-1][-2]['feature'][0] == VERB) or
            (chunk_list[-1][-1]['feature'][0] == AUXI and
             chunk_list[-1][-2]['feature'][0] == VERB))
         )
         should_insert = false
      end

      text += saisoku if should_insert
    else
      morphem_list.each_with_index do |morphem, i|
        next unless morphem_list[i + 1]
        if (morphem['feature'][0] == NOUN and
            morphem_list[i + 1]['feature'][1] == SURU)
            text += saisoku
        end
      end
    end

    morphem_list.each {|morphem|
      text += morphem['surface']
    }

    chunk_list.push(morphem_list)
  end
  return text
end
