#!/bin/bash

set -ev

PM2_COMMAND=${1:-/usr/bin/pm2}

$PM2_COMMAND install pm2-logrotate
$PM2_COMMAND set pm2-logrotate:max_size 50M
$PM2_COMMAND set pm2-logrotate:compress true
