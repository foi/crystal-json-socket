const JsonSocket = require('json-socket')
const startTime = new Date()
const net = require('net')
for (let i = 0; i < 10000; i++) {
  JsonSocket.sendSingleMessageAndReceive(1234, "127.0.0.1", {a: 12, b: 8}, (err, message) => {
    if (err) {
      console.error(err)
    }
    console.log(message);
    if (i === 9999) {
      console.log('Elapsed time: ', new Date() - startTime)
    }
  })
}

// var socket = new JsonSocket(new net.Socket()); //Decorate a standard net.Socket with JsonSocket
// socket.connect(1234, '127.0.0.1')
// socket.on('connect', function() { //Don't send until we're connected
//     socket.sendMessage({a: 12, b: 8});
//     socket.on('message', function(square) {
//         console.log(square);
//     });
//     socket.on('error', (e) => {
//       console.error(e)
//     })
//     socket.on('drain', () => {
//       console.log('drain');
//     })
// });
