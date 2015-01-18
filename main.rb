require 'rubygems'
require 'sinatra'
require 'pry'


# fix for chrome
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '13cQEz1n5F8A04GsvJ7C95rcou5zNd' 

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

# display the new user form
get '/new_player' do
  erb :new_player
end

# process input from form
post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

# begin the game. note that this http request begins a NEW round. 
# doesn't refresh old round
get '/game' do
  # create a deck and put it in session
  suits = %w(H D C S)
  values = %w(2 3 4 5 6 7 8 9 10 J K Q A)
  session[:deck] = suits.product(values).shuffle! # [['H', '9'], ['D', 'K'], ... ]
  
  # deal two cards to both players
  session[:dealer_cards] = []
  2.times { session[:dealer_cards] << session[:deck].pop }
  session[:player_cards] = []
  2.times { session[:player_cards] << session[:deck].pop }
  
  # render template
  erb :game
end