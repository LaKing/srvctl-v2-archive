#!/bin/bash

## from m1r0@hisi.hr

if $onVE && $isROOT
then ## no identation.

    hint "nodebb" "Install NodeBB"
    if [ "$CMD" == "add-cms" ] && [ "$OPA" == "nodebb" ]
    then       
    
     
## No identation --- install nodeBB ---
msg "NodeBB setup started"

dnf -y update
dnf -y install 'dnf-command(config-manager)'
dnf -y install tar git gcc-c++

install_nodejs_latest
install_mongodb

cd /srv
git clone https://github.com/NodeBB/NodeBB.git
cd NodeBB

npm -g install --unsafe-perm --verbose

#Missing

npm install colors
npm install minimist
npm install async
npm install nconf
npm install logrotate-stream
npm install winston
npm install mime
npm install jimp
npm install xregexp
npm install semver
npm install express
npm install body-parser
npm install less
npm install uglify-js
npm install templates.js

#Missing setup

npm install prompt
npm install express-session
npm install underscore
npm install underscore.deep
npm install npm # check why double needed ?!
npm install kereberos # this is questionable ?!

#Missing post setup
npm install validator
npm install cron
npm install string
npm install nodemailer
npm install html-to-text
npm install lru-cache
npm install sitemap
npm install socket.io
npm install socket.io-wildcard
npm install socketio-wildcard
npm install cookie-parser
npm install morgan
npm install passport
npm install passport-local
npm install request
npm install rimraf
npm install mkdirp
npm install daemon

#Missing for startup
npm install bcryptjs
npm install compression
npm install connect-ensure-login
npm install connect-flash
npm install connect-multiparty
npm install csurf
npm install heapdump

#Missing in nodebb log
npm install nodebb-theme-persona
npm install nodebb-rewards-essentials
npm install nodebb-widget-essentials
npm install rss
npm install serve-favicon
npm install socket.io-client
npm install socket.io-redis
npm install toobusy-js

systemctl disable httpd
systemctl stop httpd

## No identation --- install nodeBB ---


    ok
    fi ## install-joomla
fi

man '
    Use the github release of Joomla! Create configuration files.
    http://www.joomla.org/
'

