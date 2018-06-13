# COMPLETE TUTORIAL FOR CREATE API IN SINATRA APP USING MONGODB

We will learn how use [Sinatra](http://sinatrarb.com/) for create API and the non relational batabase MongoDB under Linux.

Read this document in [Italian](https://github.com/davfaz70/sinatra-myapp/blob/master/Readme.it.md)


## Getting Started

First, we must create a new folder where will put our project, in this example we going to call it: “myapp”, open the Linux shell and give this command:

```
$ cd myapp
```

Now we are in the directory, let’s go to create a text file and call it “myapp.rb”, at the moment we save it empity in our directory and going to install Sinatra and all required gems for project.
For do it we must create in directory myapp a new text file, save it with this name: “Gemfile”, create another file and save it as: “config.ru”.
This is the code that you must to put in files:

**myapp/Gemfile:**

```
source 'https://rubygems.org'

gem 'sinatra',
gem 'json',
gem 'shotgun',
gem 'slim',
gem 'thin',
gem 'mongo'
gem 'bson_ext'
gem 'sinatra-namespace', '~> 1.0'
gem 'sinatra-reloader', '~> 1.0'

```

**myapp/config.ru:**

```
require 'rubygems'
require 'bundler'

Bundler.require

require './app'
run Myapp

```

**myapp/myapp.rb:**

```
require 'sinatra'
require 'mongo'
require 'json/ext' # required for .to_json
require 'sinatra/reloader'
require 'sinatra/namespace'
```

Now we save all files and in the shell going to do this command:

```
$ bundle install
```

At the end of gems installation process, our application will can use them, we have just installed the gem Sinatra, the gem json, this is useful for build API in json and mongodb gem for manage the database.
Before use mongo database we must install it on our operating system and active it, we can do it following this [documentation](https://docs.mongodb.com/manual/administration/install-community/).

When we have installed everything, we can start, so give this command on the shell:

```
$ sudo service mongod start
```

### How mongodb work

Before continuing I suggest you to do some query in mongodb using his shell, in this way we will understand how it works, so, open a separate shell window with “Ctrl+T” and enter:

```
$ mongo
```

Now we have just open the shell of mongodb, if you give this command:

```
 help
```

you see a list of available commands, let’s go to test this command:

```
 show dbs
```

you obtain all existing database on your computer, for our experiment use the database ‘test’ with the following command:

```
 use test
```

Now we put into this db a new post:

```
 db.test.insert( {title: “shell”, body: “testing”} )
```

We have just created a new post with two attributes, title and body. Let's try now to see all the posts in the database with following command:

```
 db.test.find()
```

Now we can see the first twenty result of all elements in our db, (if you want to see more results, you must enter **it**)
In our case this should be the result:

```
{ "_id" : ObjectId("5a855f6ee421e31fb1c531e1"), "title" : "shell", "body" : "testing" }
```

Obviously your \_id field should be different.
If we want to use only this post, we must find it uniquely, let’s go to copy the id and enter:

```
 db.test.find({"_id" : ObjectId("5a855f6ee421e31fb1c531e1")})
```

We found it! Obviously we can search a post with other parameters, such as title. Example:

```
 db.test.find({"title" : "shell"})
```

With this command we get all the posts where the title field contains the word "shell", if we want to see only the body of posts we must enter:

```
 db.test.find({"title" : "shell"}).projection({"_id" : 0, "body" : 1})
```

We can also update a post using this command to indicate which element to update, which fields and what to write in those fields:

```
 db.test.update({"_id" : ObjectId("5a855f6ee421e31fb1c531e1")}, { "title" : "Hello", "body" : "World!"})
```

The complete documentation of updating is [here](https://docs.mongodb.com/getting-started/shell/update/).

Finally, for destroy an element from database we enter this command:

```
 db.test.remove({"_id" : ObjectId("5a855f6ee421e31fb1c531e1")})
```

After this little training with mongodb commands we are ready to write the code of our application in Sinatra, then we exit from the shell typing:

```
 exit
```

or going to the other tab in our terminal.

### Configuration

Open the file **myapp.rb** and let's continue to write this code:

```
configure do
  db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'test')
  set :mongo_db, db[:test]
end
```

This code configures the app saying that the DBMS is mongodb and the database is test.

Now create a new folder into myapp directory and let’s call it ‘views’, into this folder we create four files with .erb extension:

* index.erb
* new.erb
* edit.erb
* show.erb

At the moment leave these files empty and write code that help us for not repeat the same code more times into **myapp.rb:**

```
helpers do
  # a helper method to turn a string ID
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
```

here we have defined the method object_id because as we saw in the shell of mongo to find an object through its id not only the simple string is enough, but must be preceded by a method called ObjectId, here we have simplified all the processes enclosing them inside a method.

### Write the methods

**myapp.rb:**

```
get '/' do
  posts = settings.mongo_db.find().to_a.to_json
  @posts = JSON.parse(posts)
  erb :index
end
```

We have just created a new route that display in the web page that is write in index.erb file, that at the moment is empty, we have also defined a variable that, how we saw in mongodb query, contain only title and body of all posts.

Write this code into **index.erb**:

```
<% @posts.each do |post| %>
<div align="center">
  <%= post["title"] %>
  <br>
  <%= post["body"] %>
  <br>
  <a href="/show/<%= post['_id']['$oid'] %>"> Show </a> <%= " " + " " + " " %> <a href="/edit/<%= post['_id']['$oid'] %>"> Edit </a>
<hr>
<% end %>
<a href="/new"> New post </a>
</div>
```

But we still do not have a route called _new_, we have to create it, in the file **myapp.rb** so we keep writing:

```
get '/new' do
  erb :new
end
```

Perfect! Now we must only create a form for insert a new post, so in the view write:

```
<div align="center">
<form action='create' method='post'>

            <label> Title <label/>
              <input type='txt' name='title' value=' ' id='title' />
                  <br>
                  <br>
            <label> Body <label/>
              <input type='txt' name='body' value=' ' id='body' />
<br>
<br>
      <button type='submit'>Confirm!</button>
    </form>
</div>
```

In this form, when the button "Confirm!" is clicked, it will call an action create with http method post, but we not have defined this action yet, so in **myapp.rb** file write:

```
post '/create/?' do
  db = settings.mongo_db
  result = db.insert_one params
  id = result.inserted_id
  redirect to("/show/#{id}")
end
```

In the instructions of this action we clearly see a query that we used, **insert**, and params contains the parameters that we have entered in the input fields and that have been passed to the method via URL.
At the end it contains a **redirect to**, we must therefore declare the show action:

```
get '/show/:id' do |id|
  @id = id
  post = post_by_id(id)
  @post = JSON.parse(post)
  erb :show
end
```

You will have noticed something new in this method, as you see here is used post\_by\_id, which returns a variable in json format, which we will use later for APIs, the JSON.parse method returns an array that we can analyze in Ruby, this array in our case will contain the id of the object, the title and the body.
 At this point we see how to extract the data from the array inside the view **show.erb**:

```
<div align="center">
  <h3> <%= @post["title"] %> </h3>
  <br>
  <%= @post["body"] %>
  <br>
</div>
<br> <br>
<a href="/new"> New post </a>
<br> <br>
<a href="/edit/<%=@id%>"> Edit </a>
<br> <br>
 <form action="/post/<%=@id%>" method="post">
    <input type="hidden" name="_method" value="delete">
    <button type="submit">Destroy </button>
  </form>
```

We still have to define two routes, one to modify it and one to delete it, let's start with the deletion, in the file **myapp.rb** we write:

```
delete '/post/:id' do |id|
  db = settings.mongo_db
  id = object_id(id)
  post = db.find(:_id => id)
  if !post.to_a.first.nil?
    post.find_one_and_delete
  end
  redirect to("/")
end
```

At this point write the instruction for update the post:

**myapp.rb:**

```
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
```

**views/edit.erb:**

```
<div align="center">
<form action="/update/<%=@post['_id']['$oid']%>" method='post'>
<input type="hidden" name="_method" value="put">
            <label> Title <label/>
              <input type='txt' name='title' value="<%=@post['title']%>" id='title' />
                  <br>
                  <br>
            <label> Body <label/>
              <input type='txt' name='body' value="<%=@post['body']%>" id='body' />
<br>
<br>
      <button type='submit' class='btn btn-primary'>Confirm!</button>
    </form>
</div>
```

## Running the tests

Open terminal and go into myapp folder, enter the following command:

```
$ ruby myapp.rb
```

we test the operation of our application on localhost: 4567 by creating a few posts in order to have data for our APIs.

Now we have to create APIs that allow us to access, modify, view, create and delete our data directly via HTTP requests, since we must be able to access data only by writing in the address bar (and not through web pages), all the APIs that we will build will use the HTTP GET verb, otherwise we would not be able to use them from our web browser, (obviously a GET API that allows to delete an element is not secure, in fact this API is built with the verb HTTP DELETE and is used by external applications that can access the data, in this case we will build it with the HTTP GET verb in order to see the operation through the address bar).
Here is the last thing to write in our **myapp.rb**:

```
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
```

These methods are taken from [recipes of sinatra](http://recipes.sinatrarb.com/p/databases/mongo), as you can see they are very similar to what we have defined previously, but unlike them they allow access to data in json format through requests HTTP, so you can now make sure that another application uses our data, let's see how they work by typing in the address bar:

```
localhost:4567/api/v1/posts
```

try to copy any id and write

```
localhost:4567/api/v1/post/<the_id_you_copied>
```

**Now you try!**

## Built With

* [Recipes of Sinatra](http://recipes.sinatrarb.com/p/databases/mongo) - The inspiration
* [Sinatra](http://sinatrarb.com/) - The library
* [Mongodb](https://docs.mongodb.com/getting-started/shell/update/) - The DBMS

## Contributing

Check [here](https://github.com/davfaz70/sinatra-myapp/graphs/contributors)


## Authors

* **Davide Fazio** - *Initial work* - [DavFaz70](https://github.com/davfaz70)
