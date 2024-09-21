FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
  build-essential \
  postgresql-server-dev-16 \
  devscripts \
  equivs \
  lintian

COPY entrypoint.sh /entrypoint.sh
COPY debian /action/debian

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
