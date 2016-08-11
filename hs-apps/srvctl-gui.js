#!/usr/bin/env node

'use strict';

var https = require('https');
var port = 250;
var fs = require('fs');
var pty = require('pty.js');

var options = {
    cert: fs.readFileSync('/etc/srvctl/cert/d250.hu/d250.hu.pem'),
    key: fs.readFileSync('/etc/srvctl/cert/d250.hu/d250.hu.key'),
    ca: [fs.readFileSync('/etc/srvctl/CA/ca/usernet.crt.pem')],
    requestCert: true,
    rejectUnauthorized: true,
};

var express = require('express');
var app = express();
var server = https.createServer(options, app);
var io = require('socket.io')(server);
var exec = require('child_process').exec;

var Client = require('ssh2').Client;
// NOTE https://github.com/mscdex/ssh2/issues/433

// line to an array of objects
var line_to_arrob = function(line) {
    var a = line.split('\n');
    var i;
    var r = [];
    for (i = 0; i < a.length; ++i) {

        if (a[i].length > 0) r.push({
            name: a[i]
        });
    }
    return r;
};

function process_user(i) {

    var user = users_dir[i];
    var keyfile = "/var/srvctl-gui/users/" + user + "/srvctl_id_rsa";
    var key = fs.readFileSync(keyfile, 'utf8');
    var hosts = [];

    exec("cat /var/srvctl-gui/users/" + user + "/hosts", function(error, stdout, stderr) {
        if (error !== null) {
            console.log('- ' + user);
            //console.log('exec error: ' + error);
        } else {
            console.log('+ ' + user);
            hosts = line_to_arrob(stdout);
        }
        users.push({
            user: user,
            key: key,
            keyfile: keyfile,
            main: {
                hosts: hosts,
                user: user,
                debug: ''
            }
        });
    });

}

// Connected socket id clients array.
var users = [];
var users_dir = fs.readdirSync("/var/srvctl-gui/users");

var i;
for (i = 0; i < users_dir.length; ++i) {

    process_user(i);

}







app.use(express.static(__dirname + '/srvctl-gui'));
/*
app.get('/test', function(req, res) {
    res.setHeader('Content-Type', 'text/plain');
    var cert = req.connection.getPeerCertificate();

    if (cert.subject !== undefined) res.end('! Hello ' + cert.subject.CN);
    else res.end('! Hi!');

});
*/

//----------------------------------


function term2html(text) {
    // TODO add to theme
    var colors = ['#000', '#D00', '#00CF12', '#C2CB00', '#3100CA',
        '#E100C6', '#00CBCB', '#C7C7C7', '#686868', '#FF5959', '#00FF6B',
        '#FAFF5C', '#775AFF', '#FF47FE', '#0FF', '#FFF'
    ];

    // EL – Erase in Line: CSI n K.
    // Erases part of the line. If n is zero (or missing), clear from cursor to
    // the end of the line. If n is one, clear from cursor to beginning of the
    // line. If n is two, clear entire line. Cursor position does not change.
    text = text.replace(/^.*\u001B\[[12]K/mg, '');

    // CHA – Cursor Horizontal Absolute: CSI n G.
    // Moves the cursor to column n.
    text = text.replace(/^(.*)\u001B\[(\d+)G/mg, function(_, text, n) {
        return text.slice(0, n);
    });

    // SGR – Select Graphic Rendition: CSI n m.
    // Sets SGR parameters, including text color. After CSI can be zero or more
    // parameters separated with ;. With no parameters, CSI m is treated as
    // CSI 0 m (reset / normal), which is typical of most of the ANSI escape
    // sequences.
    var state = {
        bg: -1,
        fg: -1,
        bold: false,
        underline: false,
        negative: false
    };
    text = text.replace(/\u001B\[([\d;]+)m([^\u001B]+)/g, function(_, n, text) {
        // Update state according to SGR codes.
        n.split(';').forEach(function(code) {
            code = code | 0;
            if (code === 0) {
                state.bg = -1;
                state.fg = -1;
                state.bold = false;
                state.underline = false;
                state.negative = false;
            } else if (code === 1) {
                state.bold = true;
            } else if (code === 4) {
                state.underline = true;
            } else if (code === 7) {
                state.negative = true;
            } else if (code === 21) {
                state.bold = false;
            } else if (code === 24) {
                state.underline = false;
            } else if (code === 27) {
                state.negative = false;
            } else if (code >= 30 && code <= 37) {
                state.fg = code - 30;
            } else if (code === 39) {
                state.fg = -1;
            } else if (code >= 40 && code <= 47) {
                state.bg = code - 40;
            } else if (code === 49) {
                state.bg = -1;
            } else if (code >= 90 && code <= 97) {
                state.fg = code - 90 + 8;
            } else if (code >= 100 && code <= 107) {
                state.bg = code - 100 + 8;
            }
        });

        // Convert color codes to CSS colors.
        var bold = state.bold * 8;
        var fg, bg;
        if (state.negative) {
            fg = state.bg | bold;
            bg = state.fg;
        } else {
            fg = state.fg | bold;
            bg = state.bg;
        }
        fg = colors[fg] || '';
        bg = colors[bg] || '';

        // Create style element.
        var css = '';
        var style = '';
        if (bg) {
            style += 'background-color:' + bg + ';';
        }
        if (fg) {
            //style += 'color:' + fg + ';';
            css = "log_" + state.fg;
        }
        if (bold) {
            style += 'font-weight:bold;';
        }
        if (state.underline) {
            style += 'text-decoration:underline';
        }
        var html = text.
        replace(/&/g, '&amp;').
        replace(/</g, '&lt;').
        replace(/>/g, '&gt;');

        // Return HTML for this section of formatted text.
        if (style || css) {
            if (style) return '<span class="' + css + '" style="' + style + '">' + html + '</span>';
            else return '<span class="' + css + '">' + html + '</span>';
        } else {
            return html;
        }
    });

    return text.replace(/\u001B\[.*?[A-Za-z]/g, '');
}

//----------------------------------


var sc_ls = function(hix, uix, socket) {

    var conn = new Client();
    conn.on('ready', function() {
        var adat = '';
        conn.exec('/bin/srvctl ls', function(err, stream) {
            if (err) throw err;
            stream.on('close', function(code, signal) {
                conn.end();
                users[uix].main.hosts[hix].containers = line_to_arrob(adat);
                update_client(socket);
            }).on('data', function(data) {
                adat += data;
            }).stderr.on('data', function(data) {
                console.log(data);
            });
        });
    });
    conn.on('error', function(err) {
        console.log(err);
    });
    conn.on('close', function(err) {
        //console.log('ssh2 connection closed');
    });
    conn.connect({
        host: users[uix].main.hosts[hix].name,
        port: 22,
        username: users[uix].user,
        privateKey: users[uix].key,
        readyTimeout: 500
    });

};

var sc_command = function(hix, uix, cmd_json, socket) {
    console.log('ssh2 connection sc_command ' + hix + ' ' + uix + ' #srvctl ' + cmd_json.cmd);
    var conn = new Client();
    var comm = '/bin/srvctl ' + cmd_json.cmd;
    conn.on('ready', function() {
        var adat = '';
        conn.exec(comm, function(err, stream) {
            if (err) throw err;
            stream.on('close', function(code, signal) {
                conn.end();
                //users[uix].main.hosts[hix].containers = line_to_arrob(adat);
                //update_user(uix);
                //console.log('Closed ssh2 connection');
                socket.emit('lock', false);
            }).on('data', function(data) {
                adat += data;
                socket.emit('set-terminal', term2html(adat));
            }).stderr.on('data', function(data) {
                //users[uix].main.debug = data;
                //update_user(uix);
                console.log(data);
                //socket.emit('set-terminal', 'Error.');
                //socket.emit('lock', false);
            });
        });
    });
    conn.on('error', function(err) {
        //console.log(err);
        socket.emit('set-terminal', err.level + ' error.');
        socket.emit('lock', false);
    });
    conn.on('close', function(err) {
        //console.log('ssh2 connection closed');
    });
    conn.connect({
        host: users[uix].main.hosts[hix].name,
        port: 22,
        username: users[uix].user,
        privateKey: users[uix].key,
        readyTimeout: 500
    });
};

var update_client = function(socket) {
    socket.emit('set-main', users[socket.uix].main);
};

var send_main = function(socket) {
    console.log(socket.uix);
    var hix;
    for (hix = 0; hix < users[socket.uix].main.hosts.length; hix++) {
        sc_ls(hix, socket.uix, socket);

    }
};

app.get('/ssh/:user', function(req, res) {
    res.sendFile(__dirname + '/srvctl-gui/wetty.html');
});

io.on('connection', function(socket) {
    //    console.log('a user connected (id=' + socket.id + ')');

    socket.user = '';
    socket.key = '';
    socket.uix = -1;
    //socket.term = false;    

    var cert = socket.client.request.client.getPeerCertificate();
    if (cert.subject !== undefined) {
        // client is identified
        socket.user = cert.subject.CN;
        console.log(socket.user + ' connected (id=' + socket.id + ')');
        var i;
        for (i = 0; i < users_dir.length; ++i) {
            if (users[i].user === cert.subject.CN) {
                console.log("#USER-uix " + i);
                socket.key = users[i].key;
                socket.uix = i;
            }
        }
    } else return;

    if (socket.request.headers.referer.split('/')[3] === 'ssh') {

        var ssh_user = socket.request.headers.referer.split('/')[4];

        socket.term = pty.spawn('ssh', ['-p', 22, '-o', 'UserKnownHostsFile=/dev/null', '-o', 'StrictHostKeyChecking=no', '-o', 'PreferredAuthentications=publickey', '-i', users[socket.uix].keyfile, ssh_user], {

            name: 'xterm-256color',
            cols: 80,
            rows: 30
        });

        socket.term.on('data', function(data) {
            socket.emit('output', data);

        });
        socket.term.on('exit', function(code) {
            console.log((new Date()) + " PID=" + socket.term.pid + " ENDED");
        });
        socket.on('resize', function(data) {
            socket.term.resize(data.col, data.row);
        });
        socket.on('input', function(data) {
            socket.term.write(data);
        });

    }


    socket.on('get-main', function() {
        console.log('get-main (id=' + socket.id + ')');
        send_main(socket);
    });

    socket.on('sc-command', function(cmd_json) {
        console.log('sc_command (id=' + socket.id + ') ' + JSON.stringify(cmd_json));
        sc_command(cmd_json.hix, socket.uix, cmd_json, socket);
    });

    socket.on('disconnect', function() {
        console.info('Client gone (id=' + socket.id + ').');
    });

});


process.on('uncaughtException', function(e) {
    console.error('Error: ' + e);
});
server.listen(port, function() {
    port = server.address().port;
    console.log('Listening on port ' + port);
    //process.setgid('node');
    //process.setuid('node');

    // TODO use it as srvctl-gui user
});