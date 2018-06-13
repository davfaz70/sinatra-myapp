# CREAZIONE DI APP SINATRA CON MONGODB SOTTO LINUX

Adesso vedremo come usare [Sinatra](http://sinatrarb.com/) per creare API web e il database non relazionale MongoDB sotto Linux.

Leggi questo documento in [Inglese](https://github.com/davfaz70/sinatra-myapp/blob/master/Readme.md)


## Iniziamo

Per prima cosa dobbiamo creare una cartella dove metteremo il nostro progetto, nell’esempio la chiameremo “myapp”, apriamo il terminale e digitiamo:

```
$ cd myapp
```

Adesso siamo dentro la cartella, creiamo un nuovo file di testo e lo chiamiamo ‘myapp.rb’, lo salviamo vuoto dentro la nostra cartella e procediamo all’installazione di Sinatra e di tutte le gemme necessarie per il funzionamento del nostro progetto.
Per farlo creiamo sempre dentro la cartella myapp un nuovo file di testo che dovremo salvare con il nome di Gemfile, poi un file chiamato ‘config.ru’, ecco il codice da mettere dentro i file:

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

salviamo il tutto e nel terminale diamo il comando

```
$ bundle install
```

Finito il processo di installazione delle gemme, la nostra applicazione potrà utilizzarle, abbiamo installato la gemma Sinatra, la gemma json, sarà utile per costruire API in json e mongodb per gestire il database.
Prima di poter usare il DBMS mongodb dobbiamo installarlo sul nostro sistema operativo e attivarlo, per farlo dovrete segire questa [documentazione](https://docs.mongodb.com/manual/administration/install-community/).

Quando si ha finito di installare il tutto, si può digitare il seguente comando:

```
$ sudo service mongod start
```

### Come funziona mongodb

Prima vi consiglio però di fare qualche query in mongodb usando la sua shell in modo da capirne il funzionamento, aprite un’altra scheda del terminale con ctrl+T e digitate:

```
$ mongo
```

A questo punto vi si apre la shell di mongodb, digitando:

```
 help
```

vedrete tutti i comandi disponibili, provate a digitare:

```
 show dbs
```

e otterrete i database esistenti sul vostro computer, passate al database ‘test’ con il comando:

```
 use test
```

provate adesso a inserire un post da riga di comando digitando:

```
 db.test.insert( {title: “shell”, body: “prova”} )
```

Questo comando permette di creare un nuovo elemento all’interno del database con due attributi, rispettivamente title e body.
Proviamo adesso a visualizzare tutti gli elementi presenti all’interno del nostro database test, digitando il comando:

```
 db.test.find()
```

In questo modo vederemo i primi 20 risultati presenti all’interno del nostro database, (nel caso avessimo più di venti elementi possiamo digitare **it** per vedere il resto)
Nel nostro caso dovrebbe comparire questo risultato:

```
{ "_id" : ObjectId("5a855f6ee421e31fb1c531e1"), "title" : "shell", "body" : "prova" }
```

Naturalmente il vostro campo \_id sarà diverso.
A questo punto dovremmo riuscire a trovarlo in modo univoco nel caso in cui ci servisse solo questo post, copiamo l’id e digitiamo:

```
 db.test.find({"_id" : ObjectId("5a855f6ee421e31fb1c531e1")})
```

Vedremo che lo abbiamo trovato! Naturalmente possiamo cercarlo anche per altri parametri, digitando ad esempio:

```
 db.test.find({"title" : "shell"})
```

Otterremo tutti i post che hanno la parola ‘shell’ come titolo, e nel caso in cui vogliamo vedere solo il campo body e non tutto il post possiamo digitare:

```
 db.test.find({"title" : "shell"}).projection({"_id" : 0, "body" : 1})
```

Possiamo anche aggiornare un post dando questo comando dove indichiamo quale elemento aggiornare, quali campi e cosa scrivere in quei campi:

```
 db.test.update({"_id" : ObjectId("5a855f6ee421e31fb1c531e1")}, { "title" : "Hello", "body" : "World!"})
```

Una documentazione completa riguardo all’aggiornamento la si può trovare [qui](https://docs.mongodb.com/getting-started/shell/update/).

Infine per eliminare un elemento dal database si digita questo comando:

```
 db.test.remove({"_id" : ObjectId("5a855f6ee421e31fb1c531e1")})
```

Finito questo piccolo allenamento con i comandi di mongodb siamo pronti a scrivere il codice della nostra applicazione in Sinatra, usciamo quindi dalla shell o passando all’altra scheda o digitando:

```
 exit
```

oppure andando in un'altra scheda del terminale.

### Configurazione

Apri il file **myapp.rb** e continua a scrivere questo codice:

```
configure do
  db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'test')
  set :mongo_db, db[:test]
end
```

In questo modo diamo una configurazione all’app, in pratica stiamo dicendo che deve usare come database mongo e deve usare il database test.

Procediamo creando all’interno della nostra cartella myapp un’altra cartella che chiamiamo ‘views’ e dentro creiamo quattro file con estensione .erb:

* index.erb
* new.erb
* edit.erb
* show.erb

Per il momento li lasciamo vuoti.

Continuiamo a scrivere il codice necessario al funzionamento della nostra app all’interno di **myapp.rb:**

```
helpers do
  # un metodo che ritorna una stringa ID
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

qui abbiamo definito il metodo object_id perché come abbiamo visto nella shell di mongo per trovare un oggetto tramite il suo id non basta solo la semplice stringa, ma deve essere preceduta da un metodo chiamato ObjectId, qui abbiamo semplificato tutti i processi racchiudendoli dentro un metodo.

### Scrivere i metodi

**myapp.rb:**

```
get '/' do
  posts = settings.mongo_db.find().to_a.to_json
  @posts = JSON.parse(posts)
  erb :index
end
```

In questo modo noi stiamo creando un nuovo instradamento che fa vedere nella pagina web ciò che abbiamo scritto nel file index.erb, che per il momento è ancora vuoto, e anche una variabile che, come abbiamo visto nelle query di mongodb, contiene solo il titolo e il testo di ogni elemento presente nel database.

Andiamo a riempire il file **index.erb** con queste istruzioni:

```
<% @posts.each do |post| %>
<div align="center">
  <%= post["title"] %>
  <br>
  <%= post["body"] %>
  <br>
  <a href="/show/<%= post['_id']['$oid'] %>"> Visualizza </a> <%= " " + " " + " " %> <a href="/edit/<%= post['_id']['$oid'] %>"> Modifica </a>
<hr>
<% end %>
<a href="/new"> Nuovo post </a>
</div>
```

Ma noi non abbiamo ancora un instradamento chiamato _new_, dobbiamo crearlo, nel file **myapp.rb** quindi continuiamo a scrivere:

```
get '/new' do
  erb :new
end
```

Perfetto! Ora dobbiamo solo curare la vista grafica in modo da poter inserire i dati del nostro post, nel file **new.erb** scriviamo:

```
<div align="center">
<form action='create' method='post'>

            <label> Titolo <label/>
              <input type='txt' name='title' value=' ' id='title' />
                  <br>
                  <br>
            <label> Testo <label/>
              <input type='txt' name='body' value=' ' id='body' />
<br>
<br>
      <button type='submit'>Conferma!</button>
    </form>
</div>
```

Vediamo che questo form, quando verrà cliccato il pulsante di conferma chiamerà con metodo http post un’azione create, che noi non abbiamo ancora scritto da nessuna parte, quindi nel file **myapp.rb** scriviamo:

```
post '/create/?' do
  db = settings.mongo_db
  result = db.insert_one params
  id = result.inserted_id
  redirect to("/show/#{id}")
end
```

Nelle istruzioni di questa azione si vede chiaramente una delle query che abbiamo usato, **insert**, e params contiene i parametri che abbiamo inserito nei campi di input e che sono stati passati al metodo tramite URL.
Alla fine contiene un **redirect to**, dobbiamo quindi dichiarare l’azione show:

```
get '/show/:id' do |id|
  @id = id
  post = post_by_id(id)
  @post = JSON.parse(post)
  erb :show
end
```

Avrai notato qualcosa di nuovo in questo metodo, come vedi qui viene usato post\_by\_id, che ritorna una variabile in formato json, che in seguito useremo anche per le API, il metodo JSON.parse ritorna un vettore che possiamo analizzare in Ruby, questo vettore nel nostro caso conterrà l’id dell’oggetto, il title e il body.
 A questo punto vediamo come estrapolare i dati dal vettore dentro la vista **show.erb:**

```
<div align="center">
  <h3> <%= @post["title"] %> </h3>
  <br>
  <%= @post["body"] %>
  <br>
</div>
<br> <br>
<a href="/new"> Nuovo post </a>
<br> <br>
<a href="/edit/<%=@id%>"> Modifica </a>
<br> <br>
 <form action="/post/<%=@id%>" method="post">
    <input type="hidden" name="_method" value="delete">
    <button type="submit">Elimina </button>
  </form>
```

dobbiamo ancora definire due strade, una per modificarlo e una per eliminarlo, iniziamo con l’eliminazione, nel file **myapp.rb** scriviamo:

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

bene, a questo punto rimane solo la modifica del nostro post, andiamo a scrivere la strada necessaria in **myapp.rb:**

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
      <button type='submit' class='btn btn-primary'>Conferma!</button>
    </form>
</div>
```

## Testiamo l'applicazione

Andiamo sul terminale e se siamo dentro la cartella myapp digitiamo il comando:

```
$ ruby myapp.rb
```

e testiamo il funzionamento della nostra applicazione su localhost:4567 creando qualche post in modo da avere dati per le nostre API.

Adesso dobbiamo realizzare delle API che ci permettano di accedere, modificare, visualizzare, creare ed eliminare i nostri dati direttamente tramite richieste HTTP, dato che dobbiamo essere in grado di accedere ai dati solo scrivendo nella barra degli indirizzi (e non tramite viste), tutte le API che andremo a costruire useranno il verbo HTTP GET, altrimenti non saremmo in grado di usarle dal nostro browser web, (naturalmente, una API di tipo GET che permette di eliminare un elemento è tutto tranne che sicura, infatti anch’esse devono essere costruite con il verbo HTTP DELETE e vengono usate da applicazioni esterne che possono accedere ai dati, in questo caso la costruiremo con il verbo HTTP GET in modo da vederne il funzionamento tramite la barra degli indirizzi).
Ecco quindi l’ultima cosa da scrivere nel nostro **myapp.rb**:

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

Questi metodi sono presi da [ricette di Sinatra](http://recipes.sinatrarb.com/p/databases/mongo), come vedi sono molto simili a quelli che abbiamo definito precedentemente, ma a differenza di loro questi permettono di accedere ai dati puri ( in formato json ), tramite richieste HTTP, è quindi possibile adesso fare in modo che un’altra applicazione usi i nostri dati, proviamo a vedere come funzionano digitando nella barra degli indirizzi:

```
localhost:4567/api/v1/posts
```

prova a copiare un id qualsiasi e scrivi

```
localhost:4567/api/v1/post/<l'id_che_hai_copiato>
```

**Adesso prova tu!**

## Costruito con

* [Ricette di Sinatra](http://recipes.sinatrarb.com/p/databases/mongo) - L'ispirazione
* [Sinatra](http://sinatrarb.com/) - La libreria
* [Mongodb](https://docs.mongodb.com/getting-started/shell/update/) - Il DBMS

## Contributi

Controlla [qui](https://github.com/davfaz70/sinatra-myapp/graphs/contributors)


## Autori

* **Davide Fazio** - *Lavoro Iniziale* - [DavFaz70](https://github.com/davfaz70)
