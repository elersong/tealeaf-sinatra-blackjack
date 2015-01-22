# ============================================================================== Configurations

require 'rubygems'
require 'sinatra'
require 'pry'

# fix for chrome
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '13cQEz1n5F8A04GsvJ7C95rcou5zNd' 

# ============================================================================== Helper Method Definitions

helpers do
  
  def calculate_total(cards) # [['H', '9'], ['D', 'K'], ... ]
    arr = cards.map{|card| card[1]}
    
    total = 0
    arr.each do |card_value|
      if card_value == "A"
        total += 11
      else
        total += card_value.to_i == 0 ? 10 : card_value.to_i
      end
    end
    
    # correct aces
    arr.select{|element| element == "A"}.count.times do
      break if total <= 21
      total -= 10
    end
    
    total
  end
  
  def card_to_image(card) # ["H", "9"]
    image_name = ""
    
    if card[0] == "H"
      image_name << "hearts_"
    elsif card[0] == "D"
      image_name << "diamonds_"
    elsif card[0] == "C"
      image_name << "clubs_"
    else
      image_name << "spades_"
    end
    
    if card[1] == "A"
      image_name << "ace"
      
    elsif card[1] == "J" 
      image_name << "jack"
      
    elsif card[1] == "K"
      image_name << "king"
      
    elsif card[1] == "Q"
      image_name << "queen"
    else
      image_name << card[1]
    end
    
    image_name << ".jpg"
    
    image_name
  end # => String
  
end

# ============================================================================== Route Definitions & Game Logic

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
  
  # calculate totals for players
  session[:player_total] = calculate_total(session[:player_cards])
  session[:dealer_total] = calculate_total(session[:dealer_cards])
  
  # render template
  erb :game
end

# player chooses hit
post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  erb :game
end

post '/game/player/stay' do
  
end