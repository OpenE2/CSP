#!/bin/sh

. /var/etc/cspagent.conf

SERVICE={PARAMS}

if [ -z "$SERVICE" ]; then
  echo "No service specified (use sid or sid:tid:onid, in hex)"
  exit
fi

# Request the "all services" root reference and grep for selected sid, lowercase for E1 and uppercase for E2
if [ $ENIGMAV -eq 1 ]; then
  SERVICE=$(echo $SERVICE | tr '[A-Z]' '[a-z]')
  LINE=$(wget -q -O - http://$ENIGMAUSER:$ENIGMAPASS@127.0.0.1/cgi-bin/getServices?ref=1:15:fffffffe:12:ffffffff:0:0:0:0:0: | grep $SERVICE)
else
  SERVICE=$(echo $SERVICE | tr '[a-z]' '[A-Z]')
  XMLLINE=$(wget -q -O - http://$ENIGMAUSER:$ENIGMAPASS@127.0.0.1/web/getservices?sRef=1:0:1:0:0:0:0:0:0:0: | grep $SERVICE)
  if [ $(echo "$XMLLINE" | wc -l) -eq 1 ]; then
    LINE=$(expr "$XMLLINE" : ".*<e2servicereference> *\([0-9A-H\:]*\)")
  else
    LINE=$XMLLINE
  fi
fi

if [ ! $(echo "$LINE" | wc -l) -eq 1 ]; then
  echo "No matching service found, or ambigious reference: $SERVICE"
  echo "$LINE"
  exit
fi

if [ -z "$LINE" ]; then
  echo "No matching service found for: $SERVICE"
  exit
fi

echo "Zapping to service reference: $LINE"
if [ $ENIGMAV -eq 1 ]; then
  # Need to strip ; and trailing comment, match everything up to the last :
  LINE=$(expr "$LINE" : '\(.*:\)')
  wget -q -O - "http://$ENIGMAUSER:$ENIGMAPASS@127.0.0.1/cgi-bin/zapTo?path=$LINE"
else
  wget -q -O - "http://$ENIGMAUSER:$ENIGMAPASS@127.0.0.1/web/zap?sRef=$LINE"
fi
