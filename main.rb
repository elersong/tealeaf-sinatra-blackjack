require 'rubygems'
require 'sinatra'
require 'pry'

enable :sessions

# fix for running this app in Chrome
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'ohyesiknowthemuffinman'

get '/' do
  @error = session[:error]
  erb :game_setup
end

post '/process_user' do
  if params[:username].empty? || params[:difficulty].empty?
    session[:error] = "Please fill out both fields to begin."
    redirect back
  else
    session[:user] = params[:username]
    session[:number_of_decks] = params[:difficulty]
    redirect to('/registered')
  end
end

get '/registered' do
  "Successfully registered to play!"
end