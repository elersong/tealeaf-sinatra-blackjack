require 'rubygems'
require 'sinatra'

# fix for running this app in Chrome
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'ohyesiknowthemuffinman'

