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
  
  def is_number?(str)
    true if Float(str) rescue false
  end
  
  def issue_winnings
    session[:wallet] += (2 * session[:player_bet])
  end
  
  def gameover_if_gameover
    redirect '/gameover' if session[:wallet] <= 0
  end
  
  def final_score
    if session[:dealer_total] > session[:player_total]
      "The dealer won the last hand by #{session[:dealer_total] - session[:player_total]} points."
    else
      "Your final winnings total $#{session[:wallet]}."
    end
  end
end

before do
  @show_gameplay_buttons = false
  @show_new_game_button = false
  @show_gameplay_buttons_dealer = false
  @show_dealer_score = false
  @sign_up_page = false
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
  @sign_up_page = true
  erb :new_player
end

# process input from form
post '/new_player' do
  if params[:player_name].empty?
    @error = "You must enter a name."
    halt erb(:new_player)
  end
    session[:player_name] = params[:player_name]
    session[:wallet] = 100
    redirect '/bet'
end

# play again request from the form
post '/bet' do
  redirect '/bet'
end

# take the player's bet
get '/bet' do
  erb :bet
end

post '/player_bet' do
  bet = params[:player_bet]
  
  if bet.empty? || !is_number?(bet) || bet.to_i < 0
    session[:player_bet] = 1
  else
    session[:player_bet] = bet.to_i
  end
  
  if (session[:wallet] - session[:player_bet]) >= 0
    session[:wallet] -= session[:player_bet]
    redirect '/game'
  else
    @error = "You don't have enough money to make that bet."
    erb :bet
  end
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
  
  @show_gameplay_buttons = true
  
  # render template
  erb :game
end

# player chooses hit
post '/game-player-hit' do
  session[:player_cards] << session[:deck].pop
  session[:player_total] = calculate_total(session[:player_cards])
  
  # by default, show hit/stay buttons during player turn
  @show_gameplay_buttons = true
  
  # hide hit/stay button && show new game button after each round
  if session[:player_total] == 21
    @success = "Winner! You got BLACKJACK!"
    @show_gameplay_buttons = false
    @show_new_game_button = true
    issue_winnings
  elsif session[:player_total] > 21
    @error = "Sorry, it looks like you busted."
    @show_gameplay_buttons = false
    @show_new_game_button = true
    gameover_if_gameover
  end
  
  erb :game
end

post '/game-player-stay' do
  @success = "You have chosen to stay."
  @show_dealer_score = true
  
  # keep increasing until either higher than player or 17
  if session[:dealer_total] <= 17 || session[:dealer_total] < session[:player_total]
    session[:dealer_cards] << session[:deck].pop
    session[:dealer_total] = calculate_total(session[:dealer_cards])
    
    # display the button that reveals the next dealer card
    @show_gameplay_buttons_dealer = true
  end
  
  # hide hit/stay button && show new game button after each round
  if session[:dealer_total] == 21
    @success = "Oh no! The dealer got BLACKJACK!"
    @show_gameplay_buttons_dealer = false
    @show_new_game_button = true
    gameover_if_gameover
    
  elsif session[:dealer_total] > 21
    @success = "Yeah! The dealer busted!"
    @show_gameplay_buttons_dealer = false
    @show_new_game_button = true
    issue_winnings
    
  elsif session[:dealer_total] > session[:player_total]
    @show_gameplay_buttons_dealer = false
  end
  
  # when the dealer isn't drawing again, the game is over
  if @show_gameplay_buttons_dealer == false
    
    if session[:player_total] > session[:dealer_total] && session[:player_total] <= 21
      @success = "Yeah! You win!"
      issue_winnings
      
    elsif session[:player_total] < session[:dealer_total] && session[:dealer_total] <= 21
      @error = "Oh no! The dealer wins!"
      gameover_if_gameover
      
    elsif session[:player_total] == session[:dealer_total]
      @success = "Push. Nobody wins. Nobody loses."
      session[:wallet] += session[:player_bet]
    end
    
    @show_new_game_button = true
  end
  
  if session[:wallet] <= 0
    redirect '/gameover'
  else
    erb :game
  end
end

post '/game' do
  redirect '/game'
end

post '/gameover' do
  erb :gameover
end

get '/gameover' do
  erb :gameover
end