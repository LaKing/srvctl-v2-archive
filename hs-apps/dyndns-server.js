console.log('Starting dyndns-server.js');

var https = require('https');
var fs = require('fs');
var querystring = require('querystring');
var exec = require('child_process').exec;
var upd;

function processPost(request, response, callback) {
    var queryData = "";
    if (typeof callback !== 'function') return null;

    if (request.method == 'POST') {
        request.on('data', function(data) {
            queryData += data;
            if (queryData.length > 1e6) {
                queryData = "";
                response.writeHead(413, {
                    'Content-Type': 'text/plain'
                }).end();
                request.connection.destroy();
            }
        });

        request.on('end', function() {
            request.post = querystring.parse(queryData);
            callback();
        });

    } else {
        response.writeHead(405, {
            'Content-Type': 'text/plain'
        });
        response.end();
    }
}

var options = {
    key: fs.readFileSync(process.argv[2]),
    cert: fs.readFileSync(process.argv[3])
};

console.log('Certificates loaded.');

https.createServer(options, function(request, response) {
    //response.writeHead(200);
    var ip = request.connection.remoteAddress;
    var dyndnshost = request.url.substring(1);

    console.log(dyndnshost + " update request from " + ip);

    if (request.url.length < 9 || request.method !== 'POST') {
        response.writeHead(200, "OK", {
            'Content-Type': 'text/plain'
        });
        response.end('Error!');
        console.log('invalid dyndns update request from ' + ip);
    } else {

        processPost(request, response, function() {
            console.log(request.post);
            // authorize

            fs.readFile("/var/dyndns/" + dyndnshost + '.auth', 'utf8', function(err, data) {
                if (err) {
                    response.end('Internal error.');
                    return console.log(err);
                } else {
                    if (request.post.auth == data) {
                        response.writeHead(200, "OK", {
                            'Content-Type': 'text/plain'
                        });
                        fs.writeFile("/var/dyndns/" + dyndnshost + '.ip', ip, function(err) {
                            if (err) {
                                response.end('Internal error.');
                                return console.log(err);
                            } else {


                                upd = exec("/bin/bash " + __dirname + "/dyndns-update.sh " + dyndnshost, function(error, stdout, stderr) {
                                    console.log('stdout: ' + stdout);
                                    console.log('stderr: ' + stderr);
                                    if (error !== null) {
                                        console.log('exec error: ' + error);
                                        response.end(error);
                                    } else {
                                        response.end(stdout + 'OK\n');
                                    }
                                });

                            }
                        });

                    } else {
                        response.writeHead(200, "OK", {
                            'Content-Type': 'text/plain'
                        });
                        response.end('Permission denied');
                    }
                }

            });


        });

    }
}).listen(855);

process.setuid(103);

console.log('Started dyndns-server.js under uid ' + process.getuid());