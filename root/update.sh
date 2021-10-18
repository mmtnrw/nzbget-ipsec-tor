#!/bin/sh
NZBGET_BRANCH="testing-download"
mkdir -p /app/nzbget && \
curl -o /tmp/json -L http://nzbget.net/info/nzbget-version-linux.json && NZBGET_VERSION=$(grep "${NZBGET_BRANCH}" /tmp/json  | cut -d '"' -f 4) && \
curl -o /tmp/nzbget.run -L "${NZBGET_VERSION}" && \
sh /tmp/nzbget.run --destdir /app/nzbget

