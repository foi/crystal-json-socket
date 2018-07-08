const net = require('net'),
    JsonSocket = require('json-socket')

const port = 1234
const server = net.createServer()
server.listen(port)
let requests = 0
server.on('connection', (socket) => {
  socket = new JsonSocket(socket)
  socket.on('message', (message) => {
    requests = requests + 1
    console.log(message, requests)
    let result = (message.a + message.b) * (message.a + message.b)
    socket.sendEndMessage({ result: result })
  })
})
