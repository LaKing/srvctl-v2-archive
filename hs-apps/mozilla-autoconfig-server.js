// Load modules to create a http server.
var http = require("http");
var os = require('os');

// Configure our HTTP server to respond with a file-read to all requests on the mozilla autoconfig URL
// http://example.com/.well-known/autoconfig/mail/config-v1.1.xml

var xml = '';
xml += '<clientConfig version="1.1">';
xml += '<emailProvider id="D250.hu">';

xml += '<domain>%EMAILDOMAIN%</domain>';
xml += '<displayName>%EMAILADDRESS% at ' + os.hostname() + '</displayName>';
xml += '<displayShortName>%EMAILADDRESS%</displayShortName>';
xml += '<incomingServer type="imap">';
xml += '<hostname>' + os.hostname() + '</hostname>';
xml += '<port>993</port>';
xml += '<socketType>SSL</socketType>';
xml += '<authentication>password-cleartext</authentication>';
xml += '<username>%EMAILADDRESS%</username>';
xml += '</incomingServer>';

xml += '<incomingServer type="pop3">';
xml += '<hostname>' + os.hostname() + '</hostname>';
xml += '<port>995</port>';
xml += '<socketType>SSL</socketType>';
xml += '<authentication>password-cleartext</authentication>';
xml += '<username>%EMAILADDRESS%</username>';
xml += '</incomingServer>';

xml += '<outgoingServer type="smtp">';
xml += '<hostname>' + os.hostname() + '</hostname>';
xml += '<port>465</port>';
xml += '<socketType>SSL</socketType>';
xml += '<authentication>password-cleartext</authentication>';
xml += '<username>%EMAILADDRESS%</username>';
xml += '</outgoingServer>';

//xml += '<documentation url="http://'+os.hostname()+'/thunderbird-e-mail.html">';
//xml += '<descr lang="en">TB 2.0 IMAP</descr>';
//xml += '<descr lang="hu">TB 2.0 IMAP</descr>';
//xml += '</documentation>';

xml += '</emailProvider>';
xml += '</clientConfig>';

var http_server = http.createServer(function(req, res) {
    res.writeHead(200, {
        "Content-Type": "text/xml"
    });

    res.end(xml);
    console.log("Request.");

});

http_server.listen(1029);
console.log('Started mozilla-autoconfig-server.js for ' + os.hostname());