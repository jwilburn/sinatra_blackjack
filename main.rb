require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK = 21
DEALER_HITS_AT = 17
INITIAL_POT = 10000

helpers do
  def blank?(input)
    return true if input.empty?
    return true if input.nil?
    return true if input.strip.length == 0
  end

  def total(cards)
    values = cards.map{|c| c[1]}
    total = 0

    values.each do |v|
      if v == "A"
        total += 11
      elsif v.to_i == 0
        total += 10
      else
        total += v.to_i
      end
    end

    values.select { |v| v == "A" }.count.times do
      total -= 10 if total > BLACKJACK
    end
    total
  end

  def dealer_hit_stay(total)
    return true if total < DEALER_HITS_AT
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'S' then 'spades'
      when 'C' then 'clubs'
    end

    value = case card[1]
      when 'A' then 'ace'
      when 'K' then 'king'
      when 'Q' then 'queen'
      when 'J' then 'jack'
    else
      card[1]
    end

    card_name = "#{suit}_#{value}.jpg"

    "<img src='/images/cards/#{card_name}' class='card' />"
  end

  def won(msg)
    @play_again = true
    @show_hitstay = false
    session[:player_pot] = session[:player_pot] + session[:player_bet].to_i
    @winner = "#{session[:player_name]} won. #{msg}"
  end

  def lost(msg)
    @play_again = true
    @show_hitstay = false
    session[:player_pot] = session[:player_pot] - session[:player_bet].to_i
    @loser = "#{session[:player_name]} lost. #{msg}"
  end

  def tie(msg)
    @play_again = true
    @show_hitstay = false
    @winner = "Tie Game"
  end

  def blackjack_flop?
    return true if total(session[:player_cards]) == BLACKJACK
    return true if total(session[:dealer_cards]) == BLACKJACK
  end
end

####################

before do
  @show_hitstay = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new'
  end
end

get '/new' do
  session[:player_name] = nil
  session[:player_pot] = INITIAL_POT
  erb :new
end

post '/new' do
  if blank?(params[:player_name])
    @error = "Name cannot be blank / empty"
    halt erb(:new)
  else
    session[:player_name] = params[:player_name].rstrip
    redirect '/game/player/bet'
  end
end

get '/game' do
  if !session[:player_name].nil? || !session[:player_bet].nil?
    session[:current_player] = session[:player_name]
    suits = ['H', 'S', 'D', 'C']
    values = [*2..10, 'J', 'Q', 'K', 'A']
    session[:player_cards] = []
    session[:dealer_cards] = []
    session[:deck] = suits.product(values).shuffle!
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  else
    redirect '/new'
  end

  # if blackjack_flop?
  #   session[:current_player] = nil
  #   redirect '/game/compare'
  # end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = total(session[:player_cards])
  if player_total > BLACKJACK
    lost("#{session[:player_name]} busted")
  elsif player_total == BLACKJACK
    won("#{session[:player_name]} hit Blackjack")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @info = "#{session[:player_name]} chose to stay"
  @show_hitstay = false
  redirect '/game/dealer'
end

get '/game/player/bet' do
  session[:player_bet] = nil
  if session[:player_pot] == 0
    redirect '/game_over'
  else
    erb :bet
  end
end

post '/game/player/bet' do
  if blank?(params[:player_bet])
    @error = "Bet cannot be blank / empty"
    halt erb(:bet)
  elsif params[:player_bet].to_i <= 0 || params[:player_bet].to_i > session[:player_pot]
    @error = "Bet must be greater than $0 and less than $#{session[:player_pot]}"
    halt erb(:bet)
  else
    session[:player_bet] = params[:player_bet].to_i
    redirect '/game'
  end
end

get '/game/dealer' do
  @show_hitstay = false
  session[:current_player] = "dealer"
  dealer_total = total(session[:dealer_cards])

  if dealer_total > BLACKJACK
    won("Dealer busted")
  elsif dealer_total == BLACKJACK
    lost("Dealer won with Blackjack.")
  elsif dealer_total >= DEALER_HITS_AT
    redirect '/game/compare'
  else
    @dealer_hit = true
  end

  erb :game, layout: false
end

get '/game/compare' do
  @show_hitstay = false
  player_total = total(session[:player_cards])
  dealer_total = total(session[:dealer_cards])

  if player_total > dealer_total
    won("#{session[:player_name]} wins with #{player_total}")
  elsif player_total < dealer_total
    lost("Dealer wins with #{dealer_total}")
  else
    tie("Tie game")
  end

  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game_over' do
  erb :game_over
end
