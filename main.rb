require 'rubygems'
require 'sinatra'

set :sessions, true

get '/' do
  "THis is non-html"
end

get '/welcome' do
  erb :welcome
end


get '/sub' do
  erb :"/sub/sub"
end
