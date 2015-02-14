# app.rb

require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require './environments.rb'

set :public_folder , 'public'
#rake db:create_migration NAME=create_posts
enable :sessions

set :sessions => true

class Users < ActiveRecord::Base
  validate :id
  validate :username
  validate :password
  validate :email
  validate :role
  validate :status
end

class Photos < ActiveRecord::Base
  validate :name
  validate :format
  validate :user_id
end

class Messages < ActiveRecord::Base
  validate :id
  validate :image_id
  validate :content
  validate :date
  validate :user_name
end

class Friends < ActiveRecord::Base
  validate :first_id
  validate :second_id
  validate :status
end

class Requests < ActiveRecord::Base
  validate :username_from
  validate :username_to
  validate :status
end

configure :development do
  register Sinatra::Reloader
end

configure :development do
  set(:session_secret, 'hello')
end

@not_found = false

get '/register' do
  File.read(File.join(settings.public_folder,'register.html'))
end

get '/removeUser/:name' do
  if session[:role] == "admin"
    user = Users.find_by(username: params[:name])
    user.destroy
    redirect '/main'
  end
end

get '/upgradeUser/:name' do
  if session[:role] == "admin"
    user = Users.find_by(username: params[:name])
    user.role = "admin"
    user.save
    redirect '/main'
  end  
end

get '/message' do
  username = session[:username]
  content = params[:content]
  date = Time.now.strftime("%d/%m/%Y %H:%M")
  img_id = params[:id]
  Messages.create(image_id: img_id, content:content, date: date, user_name: username)
  redirect '/main'
end

post '/createUser' do
  begin
    query_result = Users.find_by(username: params[:username])
    if not query_result.nil?
      "Username already taken or email not accurate! <a href='/register'> Return to register</a>"
	else
	  user = Users.create(username: params[:username], password: params[:password], email: params[:email], role: 'user',status: 1)
	  session[:username], session[:role], session[:user_id] = user.username, user.role, user.id
	  Dir.mkdir "public/image/" + user.username
	  erb :main
	end
  rescue Exception => msg
	"Exception : Username already taken or email not accurate!"\
	" <a href='/register'> Return to register</a>"
  end
end

get '/logout' do
  session[:username] = nil
  session[:role] = nil
  session[:id] = nil
  @not_found = false
  redirect "/login"
end

['/','/index','/login'].each do |path|
  get path do
    if session[:username].nil?
      erb :login
	else 
	  redirect '/main'
	end
  end
end

['/','/index','/login'].each do |path|
  post path do	
    if session[:username].nil?
      erb :login
	else
	  not_found = false
	  redirect '/main'
	end
  end
end

post '/uploadImage' do
  begin
    path = "public/image/" + session[:username] + "/" + params["myfile"][:filename]
	File.open(path, "wb") do |f|
  	  f.write(params["myfile"][:tempfile].read)
	end
	format = params["myfile"][:filename].split(".").last
	Photos.create(name: params["myfile"][:filename], format: format, user_id: session[:user_id])
	redirect '/main'
  rescue Exception => msg
	puts msg
	"An error occured during upload.Go back to main <a href='/main'> Click </a>" 
  end
end

get '/remove/:id' do
  begin
    row = Friends.find_by(first_id: session[:user_id], second_id: params[:id])
    row.destroy if row
	row = Friends.find_by(first_id: params[:id], second_id: session[:user_id])
    row.destroy if row 
	redirect '/main'
  rescue Exception => msg
	redirect '/main'
  end
end

get '/request/:id' do
  begin
    Friends.create(first_id: session[:user_id], second_id: params[:id].to_i, status: 3)
	Friends.create(first_id: params[:id].to_i, second_id: session[:user_id], status: 2)
	redirect '/main'
  rescue Exceptin => msg 
	redirect '/main'
  end
end

get '/accept/:id' do
  row = Friends.find_by(first_id: session[:user_id], second_id: params[:id])
  row.status = 1
  row.save
  row = Friends.find_by(first_id: params[:id], second_id: session[:user_id])
  row.status = 1
  row.save	
  redirect '/main'
end

get '/friend/:name' do
  session[:friend] = params[:name]
  id = Users.find_by(username: params[:name]).id
  status = Friends.find_by(first_id: session[:user_id],second_id: id).status
  session[:friend] = nil if status != 1
  redirect '/main'
end

get '/query' do
  session[:query] = params[:searchUser]
  redirect '/main'
end

get  '/main' do
  if session[:role].nil?
    begin
	  user = Users.find_by(username: params[:username], password: params[:password])
	  session[:username], session[:role], session[:user_id] = user.username, user.role, user.id
	  @not_found = false
	rescue Exception => msg
	  puts msg
	  @not_found = true;
	  redirect "/login"
	end
  end
  if session[:role] == 'user'
    if session[:query]
      @queryList = search(session[:query])
      session[:query] = nil
    end
    unless session[:friend] 
	  @name = session[:username]
	  @imageList = Photos.where("user_id=?", session[:user_id])
	else
	  @name = session[:friend]
	  friend_id = Users.find_by(username: @name).id
	  @imageList = Photos.where("user_id=?", friend_id)
	  session[:friend] = nil
	end
	id = session[:user_id]
	string_query = "INNER JOIN users ON users.id = friends.second_id WHERE friends.first_id = #{id}"
	friendListId = Friends.joins(string_query);
	string_query = "INNER JOIN friends ON users.id = friends.second_id WHERE friends.first_id = #{id}"
	friendListName = Users.joins(string_query);
	@friendList = friendListId.zip(friendListName)
	erb :main
  else
  	@userList = Users.all
	erb :admin
  end
end

post '/main' do
  if session[:role].nil?
    begin
      user = Users.find_by(username: params[:username], password: params[:password])
	  session[:username], session[:role], session[:user_id] = user.username, user.role, user.id
	  @not_found = false
    rescue Exception => msg
      puts msg
	  @not_found = true;
	  redirect "/login"
    end
  end
  if session[:role] == 'user'
    @name = session[:username]
	@imageList = Photos.where("user_id=?", session[:user_id])
	id = session[:user_id]
	string_query = "INNER JOIN users ON users.id = friends.second_id WHERE friends.first_id = #{id}"
	friendListId = Friends.joins(string_query);
	string_query = "INNER JOIN friends ON users.id = friends.second_id WHERE friends.first_id = #{id}"
	friendListName = Users.joins(string_query);
	@friendList = friendListId.zip(friendListName)
	@not_found = false
	erb :main
  else
  	@userList = Users.all
	erb :admin
  end
end

def search text
  result = Array.new
  id = session[:user_id]
  query_string = "SELECT * FROM users WHERE users.id != #{id} AND users.id"\
  				 " NOT IN (SELECT second_id FROM friends WHERE first_id = #{id})"
  query_result = Users.find_by_sql(query_string)
  if text != ""
    query_result.each do |row|
      result << row if row.username.starts_with?(text)
    end
  end
  result
end

get '/foo' do
  session['m'] = 'Hello World!'
  redirect '/bar'
end

get '/bar' do
  <<-ENDRESPONSE
    Ruby:    #{RUBY_VERSION}
    Rack:    #{Rack::VERSION}
    Sinatra: #{Sinatra::VERSION}
    #{session['m'].inspect}
  ENDRESPONSE
end
#get '/' do
  #@user = Users.create(:username => 'al',:password => 'al',:email => 'al@mail.bg',:role => 'user')
 # user.email
  #if @user.save
  #	"Success!"
 # else "Failure!"
  #end
#end