require 'appengine-rack'

AppEngine::Rack.configure_app(
  :application => 'kunitada-bot',
  :version => 1
)

require 'main'

run Sinatra::Application
