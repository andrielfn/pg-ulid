FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
  build-essential \
  postgresql-server-dev-all \
  devscripts \
  debhelper \
  dh-make \
  fakeroot

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
