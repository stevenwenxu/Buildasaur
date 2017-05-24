var app = require('express')();
var server = require('http').createServer(app);
var io = require('socket.io')(server);

app.get('/', function (req, res) {
    res.sendFile(__dirname + '/index.html');
});

io.on('connection', function (socket) {
    socket.on('rebuild-request', function(data) {
        console.log('got request to rebuild: ' + JSON.stringify(data));
        socket.broadcast.emit('rebuild', data);
    });
});

server.listen(5000, function() {
    console.log('listening on port 5000');
});
