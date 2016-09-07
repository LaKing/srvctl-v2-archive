#!/bin/node

// Express with http and https

// Boilerplates?

// for passport authentication, 
// https://github.com/scotch-io/easy-node-authentication

// note, requires mongod

// dnf -y install mongodb
// systemctl enable mongod
// systemctl start mongod

// Angular 2 https://github.com/mschwarzmueller/angular-2-beta-boilerplate
// Bootstrap with angular 2 https://github.com/valor-software/ng2-bootstrap

function log(txt) {
    console.log(new Date(), txt);
}

var fs = require('fs');
var http = require('http');
var https = require('https');
var privateKey = fs.readFileSync('/var/codepad/localhost.key', 'utf8');
var certificate = fs.readFileSync('/var/codepad/localhost.crt', 'utf8');
var credentials = {
    key: privateKey,
    cert: certificate
};
var express = require('express');
var app = express();

// express configuration
app.use(express.static('public'));

var httpServer = http.createServer(app);
var httpsServer = https.createServer(credentials, app);

httpServer.listen(8080);
httpsServer.listen(8443);

log("Project started.");