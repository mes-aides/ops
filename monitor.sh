#!/usr/bin/env bash
#
# Execution of this script is available at ssh -i .ssh/mes-aides-bot monitor@mes-aides.gouv.fr

MAX_DISK_USAGE=90  # percentage
PARTITION_TO_MONITOR=root
PORT=8000
OPENFISCA_PORT=12000
PROTOCOL=https
PUBLIC_HOST=mes-aides.gouv.fr


disk_usage=$(df | grep $PARTITION_TO_MONITOR | tr -s ' ' | cut -d ' ' -f 5 | tr -d '%')
echo "$PARTITION_TO_MONITOR disk usage: $disk_usage%"

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

if ! test $disk_usage -lt $MAX_DISK_USAGE
then let failures++
fi

echo "$failures failed tests"

exit $failures
