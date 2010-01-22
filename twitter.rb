require 'appengine-apis/urlfetch'
require 'json'

class Twitter
  def initialize(username, password)
    @req = Net::HTTP::Get.new('/')
    @req.basic_auth username, password
  end

  def update(body, in_reply_to)
    url = 'http://twitter.com/statuses/update.json'
    request(url, 'POST', { :payload => "status=#{body}&in_reply_to_status_id=#{in_reply_to}" })
  end

  def friends_timeline(screen_name)
    url = "http://twitter.com/statuses/friends_timeline/#{screen_name}.json"
    res = request(url)
    JSON.parser.new(res.body).parse
  end

  def tejimaya_timeline
    url = "http://api.twitter.com/1/nitro_idiot/lists/tejimaya/statuses.json"
    res = request(url)
    JSON.parser.new(res.body).parse
  end

  private

  def request(url, method = 'GET', options = {})
    options[:method]  = method
    options[:headers] = { 'Authorization' => @req['Authorization'] }
    AppEngine::URLFetch.fetch(url, options)
  end
end
