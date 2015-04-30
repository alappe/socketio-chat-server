config = require 'getconfig'
Twitter = require 'node-twitter'
Hapi = require 'hapi'
server = new Hapi.Server()
server.connection port: config.port
io = (require 'socket.io')(server.listener, serveClient: false)
connectionPool = []

# Optional twitter stuff…
t = config.twitter
twitterStreamClient = null
if t.consumer_key isnt '' and t.consumer_secret isnt ''
  if t.token isnt '' and t.token_secret isnt ''
    console.log 'trying to start twitter'
    twitterStreamClient = new Twitter.StreamClient t.consumer_key, t.consumer_secret, t.token, t.token_secret
    twitterStreamClient.on 'tweet', (tweet) ->
      data =
        id: tweet.id_str
        name: tweet.user.screen_name
        content: tweet.text
        date: new Date()
        twitter: true
      console.log 'twitter message', data
      connectionPool.forEach (c) -> c.emit 'message', data

io.on 'connection', (socket) ->
  console.log 'connection!'
  socket.on 'message', (data) ->
    console.log 'received message', data
    connectionPool.forEach (c) ->
      unless c is socket
        c.emit 'message', data
  connectionPool.push socket

server.route
  method: 'GET'
  path: '/{param*}'
  handler:
    directory:
      path: 'public'

server.start ->
  if twitterStreamClient?
    twitterStreamClient.start ['nodejs', 'iojs', 'io.js', 'node.js', 'mannheim']
  console.log "Server listening on port http://localhost:#{config.port}"
