var nodeStatic = require('node-static');
var http = require('http');

var file = new nodeStatic.Server(__dirname + '/src');
var port = 3001;
http
  .createServer(function (req, res) {
    file.serve(req, res);
  })
  .listen(port);

console.log(`started on: http://localhost:${port}/`);
