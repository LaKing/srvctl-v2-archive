// in this version we create the static server on demand.
// another approach would be to use res.sendFile(filepath);
// and propably the ultimate would be loading files into memory and serve from there ...
// but actually measurment tests say that we get a file served within ~0.150ms .) ..
// note that we will use only HTTP, as pound does not know to serve emergency http ...

var finalhandler = require('finalhandler');
var http = require('http');
var serveStatic = require('serve-static');

var server = http.createServer(function onRequest(req, res) {

    //logging the request
    console.log(req.headers.host, req.url, req.headers['user-agent'], req.headers['x-forwarded-for']);

    var host = req.headers.host;
    if (host.substring(0, 4) === 'www.') host = req.headers.host.substring(4);

    // handling the request
    var done = finalhandler(req, res);
    var serve = serveStatic('/var/static-server/' + req.headers.host);
    serve(req, res, done);

});
// Listen
server.listen(1280);
console.log("srvctl static-server started");