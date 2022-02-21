#!/bin/sh
# These values can be overwritten with env variables
LOOP="${LOOP:-false}"
LOOP_DELAY="${LOOP_DELAY:-60}"
DB_SAVE="${DB_SAVE:-false}"
DB_HOST="${DB_HOST:-http://localhost:8086}"
DB_NAME="${DB_NAME:-speedtest}"
DB_USERNAME="${DB_USERNAME:-admin}"
DB_PASSWORD="${DB_PASSWORD:-password}"
DB_BUCKET="${DB_BUCKET:-}"
DB_ORG="${DB_ORG:-}"
DB_APICODE="${DB_APICODE:-}"

run_speedtest()
{
    DATE=$(date +%s)
    RDATE=$(date +"%Y-%m-%dT%H:%M:%S")
    HOSTNAME=$(hostname)

    # Start speed test
    echo "Running a Speed Test..."
    JSON=$(speedtest --accept-license --accept-gdpr -f json)
    DOWNLOAD="$(echo $JSON | jq -r '.download.bandwidth')"
    UPLOAD="$(echo $JSON | jq -r '.upload.bandwidth')"

    # The next two lines show the results on the console (and the log)
    echo "Your download speed at $RDATE is $(($DOWNLOAD / 125000 )) Mbps ($DOWNLOAD Bytes/s)."
    echo "Your upload speed at $RDATE is $(($UPLOAD / 125000 )) Mbps ($UPLOAD Bytes/s)."

    # Save results in the database
    if $DB_SAVE;
    then
        echo "Saving values to database..."
        curl -s -S -XPOST "$DB_HOST/api/v2/write?org=$DB_ORG&bucket=$DB_BUCKET&db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --header "Authorization: Token $DB_APICODE" --data-binary "download,host=$HOSTNAME value=$DOWNLOAD $DATE"
        curl -s -S -XPOST "$DB_HOST/api/v2/write?org=$DB_ORG&bucket=$DB_BUCKET&db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --header "Authorization: Token $DB_APICODE" --data-binary "upload,host=$HOSTNAME value=$UPLOAD $DATE"
        echo "Values saved."
    fi

    # Now the ping test
    echo "Running the ping Test now..."
    PINGREPCF=$(ping -qc1 1.1.1.1 2>&1 | awk -F'/' 'END{ print (/^rtt/? ""$5"":"9999") }')
    PINGREPGG=$(ping -qc1 8.8.8.8 2>&1 | awk -F'/' 'END{ print (/^rtt/? ""$5"":"9999") }')
    PINGREPOD=$(ping -qc1 208.67.222.222 2>&1 | awk -F'/' 'END{ print (/^rtt/? ""$5"":"9999") }')

    # The next line outputs the ping results to the console (and the log)
    echo "Your Ping to Cloudflare DNS 1.1.1.1 is $(PINGREPCF) ms."
    echo "Your Ping to Google DNS 8.8.8.8 is $(PINGREPGG) ms."
    echo "Your Ping to OpenDNS 208.67.222.222 is $(PINGREPOD) ms."

    # Now saving the Ping result to the database
    if $DB_SAVE;
    then
        echo "Saving ping test value to database..."
        curl -s -S -XPOST "$DB_HOST/api/v2/write?org=$DB_ORG&bucket=$DB_BUCKET&db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --header "Authorization: Token $DB_APICODE" --data-binary "pingresults,host=$HOSTNAME value=$PINGREPCF $DATE"
        curl -s -S -XPOST "$DB_HOST/api/v2/write?org=$DB_ORG&bucket=$DB_BUCKET&db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --header "Authorization: Token $DB_APICODE" --data-binary "pingresults,host=$HOSTNAME value=$PINGREPGG $DATE"
        curl -s -S -XPOST "$DB_HOST/api/v2/write?org=$DB_ORG&bucket=$DB_BUCKET&db=$DB_NAME&precision=s&u=$DB_USERNAME&p=$DB_PASSWORD" --header "Authorization: Token $DB_APICODE" --data-binary "pingresults,host=$HOSTNAME value=$PINGREPOD $DATE"
        echo "Values saved."
    fi

}

if $LOOP;
then
    while :
    do
        run_speedtest
        echo "Running next test in ${LOOP_DELAY}s..."
        echo ""
        sleep $LOOP_DELAY
    done
else
    run_speedtest
fi
