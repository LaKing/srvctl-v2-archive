console.log('Starting dyndns-server.js');

var https = require('https');
var fs = require('fs');

var options = {
    key: fs.readFileSync('/var/srvctl-host/dyndns/key.pem'),
    cert: fs.readFileSync('/var/srvctl-host/dyndns/crt.pem')
};

console.log('Certificates loaded.');

https.createServer(options, function(req, res) {
    res.writeHead(200);
    res.end('hello world\n');
}).listen(1030);

console.log('Started dyndns-server.js');

