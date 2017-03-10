#!/usr/bin/env node

/** This server exposes the monitor shell script over HTTP.
* This makes it possible to monitor its status over simple web-based tools.
*/

var http = require('http');
var exec = require('child_process').execFile;

var PORT = 8887;


http.createServer(function(req, res) {
    exec('/home/monitor/monitor.sh', function(error, stdout, stderr) {
        res.writeHead(error ? 500 : 200, {
            'Content-Type': 'text/plain'
        });

        res.write(stdout);

        res.end();
    });
}).listen(PORT);
