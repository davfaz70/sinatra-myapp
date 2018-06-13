require 'sinatra'
require 'mongo'
require 'json/ext' # required for .to_json
require 'sinatra/reloader'
require 'sinatra/namespace'

configure do
  db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'test')
  set :mongo_db, db[:test]
end

get '/' do
  posts = settings.mongo_db.find().to_a.to_json
  @posts = JSON.parse(posts)
  erb :index
end

get '/new' do
  erb :new
end

post '/create/?' do
  db = settings.mongo_db
  result = db.insert_one params
  id = result.inserted_id
  redirect to("/show/#{id}")
end

get '/show/:id' do |id|
  @id = id
  post = post_by_id(id)
  @post = JSON.parse(post)
  erb :show
end

delete '/post/:id' do |id|
  db = settings.mongo_db
  id = object_id(id)
  post = db.find(:_id => id)
  if !post.to_a.first.nil?
    post.find_one_and_delete
  end
  redirect to("/")
end

get '/edit/:id' do |id|
  post = post_by_id(id)
  @post = JSON.parse(post)
  erb :edit
end

put '/update/:id/?' do
  @id = params[:id]
  id = object_id(params[:id])
  settings.mongo_db.find(:_id => id).
    find_one_and_update('$set' => request.params)
  redirect to("/show/#{@id}")
end


namespace '/api/v1' do

  get '/new_post/?' do
    content_type :json
    db = settings.mongo_db
    result = db.insert_one params
    db.find(:_id => result.inserted_id).to_a.first.to_json
  end

  get '/collections/?' do
    content_type :json
    settings.mongo_db.database.collection_names.to_json
  end


  get '/posts/?' do
    content_type :json
    settings.mongo_db.find.to_a.to_json
  end

  get '/post/:id/?' do
    content_type :json
    post_by_id(params[:id])
  end

  # update the post specified by :id, setting its
  # contents to params, then return the full post
  get '/update/:id/?' do
    content_type :json
    id = object_id(params[:id])
    settings.mongo_db.find(:_id => id).
      find_one_and_update('$set' => request.params)
    post_by_id(id)
  end

  # update the post specified by :id, setting just its
  # name attribute to params[:name], then return the full
  # post
  get '/update_title/:id/?' do
    content_type :json
    id   = object_id(params[:id])
    title = params[:title]
    settings.mongo_db.find(:_id => id).
      find_one_and_update('$set' => {:title => title})
    post_by_id(id)
  end

  # delete the specified post and return success
  get '/remove/:id' do
    content_type :json
    db = settings.mongo_db
    id = object_id(params[:id])
    posts = db.find(:_id => id)
    if !posts.to_a.first.nil?
      posts.find_one_and_delete
      {:success => true}.to_json
    else
      {:success => false}.to_json
    end
  end


end


helpers do
  # a helper method to turn a string ID
  # representation into a BSON::ObjectId
  def object_id val
    begin
      BSON::ObjectId.from_string(val)
    rescue BSON::ObjectId::Invalid
      nil
    end
  end

  def post_by_id id
    id = object_id(id) if String === id
    if id.nil?
      {}.to_json
    else
      post = settings.mongo_db.find(_id: id).to_a.first
      (post || {}).to_json
    end
  end
end
