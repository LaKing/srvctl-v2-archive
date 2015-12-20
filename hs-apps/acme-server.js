// Load modules to create a http server.
var http = require("http");
var fs = require('fs');

// Configure our HTTP server to respond with a file-read to all requests on the acme URL.
var http_server = http.createServer(function(req, res) {
    res.writeHead(200, {
        "Content-Type": "text/plain"
    });
    if (req.url.substring(0, 28) == "/.well-known/acme-challenge/" && req.url.length > 28) {

        var ch = req.url.substring(28);
        var file = '/var/acme/.well-known/acme-challenge/' + ch;

        fs.access(file, fs.R_OK, function(err) {
            if (!err) {
                var content = fs.readFileSync(file).toString();
                console.log("CONTENT: " + content);
                res.end(content);
            } else {
                console.log("CANNOT READ: " + ch);
                res.end("CANNOT READ: " + ch);
            }

        });

    } else {
        res.end("INVALID URL: " + req.url);
        console.log("INVALID URL: " + req.url);
    }
});

http_server.listen(1028);
console.log('Started acme-server.js');