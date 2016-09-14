// server.js
function log(txt) {
    console.log(new Date(), txt);
}
// set up ======================================================================
var fs = require('fs');
var http = require('http');
var https = require('https');
var privateKey = fs.readFileSync('/var/codepad/localhost.key', 'utf8');
var certificate = fs.readFileSync('/var/codepad/localhost.crt', 'utf8');
var credentials = {
    key: privateKey,
    cert: certificate
};

// get all the tools we need
var express = require('express');
var app = express();
var mongoose = require('mongoose');
var passport = require('passport');
var flash = require('connect-flash');

var morgan = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var session = require('express-session');

var configDB = require('./config/database.js');

// configuration ===============================================================
mongoose.connect(configDB.url); // connect to our database

require('./config/passport')(passport); // pass passport for configuration

// set up our express application
app.use(morgan('dev')); // log every request to the console
app.use(cookieParser()); // read cookies (needed for auth)
app.use(bodyParser.json()); // get information from html forms
app.use(bodyParser.urlencoded({
    extended: true
}));

app.set('view engine', 'ejs'); // set up ejs for templating
app.use('/static', express.static('static'));

// required for passport
app.use(session({
    secret: 'this-is-dathold-aaasdaas'
})); // session secret
app.use(passport.initialize());
app.use(passport.session()); // persistent login sessions
app.use(flash()); // use connect-flash for flash messages stored in session

// routes ======================================================================
require('./app/routes.js')(app, passport); // load our routes and pass in our app and fully configured passport

// req.headers["accept-language"] examples
// en-US,en;q=0.8,hu;q=0.6,de;q=0.4
// en-US,en;q=0.5

// launch ======================================================================
var httpServer = http.createServer(app);
var httpsServer = https.createServer(credentials, app);

httpServer.listen(8080);
httpsServer.listen(8443);
log("App started.");