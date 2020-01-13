#!/usr/bin/env bash
#

MAX_DISK_USAGE=90  # percentage
PORT=8000
OPENFISCA_PORT=2000
PROTOCOL=https
PUBLIC_HOST=`hostname`
MAIN_PUBLIC_HOST=mes-aides.org
DEPLOYED_DIRECTORY=/home/main/mes-aides-ui

failures=0
if ! curl -sL -w "OpenFisca\t GET %{url_effective} -> %{http_code}\\n" http://localhost:$OPENFISCA_PORT -o /dev/null
then let failures++
fi

if ! curl -sL -w "App (locally)\t GET %{url_effective} -> %{http_code}\\n" http://localhost:$PORT -o /dev/null
then let failures++
fi

if ! curl -sL -w "App (on public internet)\t GET %{url_effective} -> %{http_code}\\n" $PROTOCOL://$PUBLIC_HOST -o /dev/null
then let failures++
fi

if ! curl -sL -w "App (on public internet)\t GET %{url_effective} -> %{http_code}\\n" $PROTOCOL://$MAIN_PUBLIC_HOST -o /dev/null
then let failures++
fi

disk_usage=$(df | grep /$ | tr -s ' ' | cut -d ' ' -f 5 | tr -d '%')
echo "$Disk usage on /: $disk_usage%"
if ! test $disk_usage -lt $MAX_DISK_USAGE
then let failures++
fi

function show_repository_stats {
    echo

    cd $2
    echo "Deployed version of $1 (in $2):"
    git log --pretty=oneline -1
    echo -n "Deployed at "
    stat -c %y .git
}

show_repository_stats application $DEPLOYED_DIRECTORY

if [[ $failures -gt 0 ]]
then
	echo "**********************"
	echo "* SOMETHING IS WRONG *"
	echo "*   $failures failed tests   *"
	echo "**********************"
fi

exit $failures
