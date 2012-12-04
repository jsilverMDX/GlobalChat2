# Ugly mess of a program, I'll admit it
# But it works.
# Node GC2 Server in Coffee
# Full support for GC2 Protocol v3
# Support: Scrollback
# Coming soon: Logsaving. Nexus Pinging.

net = require("net")
util = require("util")

Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

Array::remove = (element) ->
  for e, i in this when e is element
    this.splice(i, 1)

GUID = ->
  S4 = ->
    Math.floor(Math.random() * 0x10000).toString 16
  S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4()

log = (msg) ->
  #unless msg.indexOf('PING') > 0 || msg.indexOf('PONG') > 0
  console.log "#{msg}\n"

p = (obj) ->
  log util.inspect(obj)

class Client
  constructor: (stream) ->
    @stream = stream
    @name = null

buffer = []
sockets = []
server_name = "GlobalChatNode"
password = ""
port = 9994
scrollback = true
handle_keys = {}
socket_keys = {}
handle_last_pinged = {}
handles = []
sockets = []

broadcast = (message, sender) ->
  for c in sockets when c.stream isnt sender
    sock_send c.stream, message
  p message
remove_user_by_handle = (handle) ->
  ct = ct for ct, nick of handle_keys when nick is handle
  socket = socket for socket, ctkn of socket_keys when ctkn is ct
  sockets.remove socket
  handles.remove handle
  delete handle_keys[ctoken] for ctoken, handle of handle_keys when ctoken is ct
  delete socket_keys[socket] for socket, ctoken of socket_keys when ctoken is ct
  try
    broadcast_message(socket, "LEAVE", [handle])
  catch e
    log "failed to broadcast LEAVE for clone handle #{handle}"
remove_dead_socket = (socket) ->
  sockets.remove socket
  ct = socket_keys[socket]
  handle = handle_keys[ct]
  handles.remove handle
  delete handle_keys[chattoken] for chattoken, handle of handle_keys when chattoken is ct
  delete socket_keys[socket] for socket, chattoken of socket_keys when chattoken is ct
check_token = (chat_token) ->
  sender = handle_keys[chat_token]
  return sender?
get_handle = (chat_token) ->
  sender = handle_keys[chat_token]
  return sender
send_message = (io, opcode, args) ->
  msg = opcode + "::!!::" + args.join("::!!::")
  sock_send io, msg
sock_send = (io, msg) ->
  p msg
  msg = "#{msg}\0"
  if io? && io.writable
    io.write msg
broadcast_message = (sender, opcode, args) ->
  msg = opcode + "::!!::" + args.join("::!!::")
  broadcast msg, sender
build_chat_log = ->
  return "" if scrollback == false
  out = ""
  if buffer.length > 30
    displayed_buffer = buffer.slice(buffer.length-30, buffer.length)
  else
    displayed_buffer = buffer
  displayed_buffer.forEach (msg) ->
    out += "#{msg[0]}: #{msg[1]}\n"
  out
clean_handles = ->
  remove_user_by_handle(v) for k, v of handle_keys when (handle_last_pinged[k]? && handle_last_pinged[k] < (new Date().getTime() - 30*1000))
build_handle_list = ->
  return handles.unique().join("\n")
parse_line = (line, io) ->
  parr = line.split("::!!::")
  command = parr[0]
  if command == "SIGNON"
    handle = parr[1]
    pass = parr[2]
    if handles.length != 0 && handles.indexOf(handle) > 0
      send_message(io, "ALERT", ["Your handle is in use."])
      io.close
      return
    if !handle? || handle == ""
      send_message(io, "ALERT", ["You cannot have a blank name."])
      #remove_dead_socket io
      io.close
      return
    if ((password == pass) || (!(pass?) && (password == "")))
      # uuid are guaranteed unique
      chat_token = GUID()
      handle_keys[chat_token] = handle
      socket_keys[io] = chat_token
      handles.push handle
      sockets.push io
      send_message(io, "TOKEN", [chat_token, handle, server_name])
      broadcast_message(io, "JOIN", [handle])
    else
      send_message(io, "ALERT", ["Password is incorrect."])
      io.close
    return

  # auth
  chat_token = parr[parr.length - 1]

  if check_token(chat_token)
    handle = get_handle(chat_token)
    if command == "GETHANDLES"
      send_message(io, "HANDLES", [build_handle_list()])
    else if command == "GETBUFFER"
      out = build_chat_log()
      send_message(io, "BUFFER", [out])
    else if command == "MESSAGE"
      msg = parr[1]
      buffer.push [handle, msg]
      broadcast_message(io, "SAY", [handle, msg])
    else if command == "PING"
      unless handles.indexOf(handle) > 0
        handles.push handle
      handle_last_pinged[handle] = new Date().getTime()
    else if command == "SIGNOFF"
      handles.remove handle
      broadcast_message(null, "LEAVE", [handle])
      io.end
pong_everyone = ->
  broadcast_message(null, "PONG", [build_handle_list()])
  clean_handles

server = net.createServer((socket) ->
  socket.setTimeout 0
  socket.setEncoding "utf8"
  socket.setKeepAlive true
  socket.setNoDelay false
  client = new Client(socket)
  client.name = socket.remoteAddress + ":" + socket.remotePort
  sockets.push client

  socket.on "data", (data) ->
    line = data.match(/[^\0]+/).toString() #magic part
    p line
    parse_line line, socket

  socket.on "end", ->
    log "FIN recvd"
    socket.end
    remove_dead_socket(socket)

).listen port

log "#{server_name} running on GlobalChat2 3.0 platform Replay:#{scrollback} Passworded:#{password != ''}"

setInterval(pong_everyone, 5000)