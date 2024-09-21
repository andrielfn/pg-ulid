FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
  build-essential \
  devscripts \
  equivs \
  lintian \
  curl \
  lsb-release \
  gnupg

# Add PostgreSQL repository
RUN sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' &&
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

# Update and install PostgreSQL 16
RUN apt-get update && apt-get install -y postgresql-server-dev-16

COPY entrypoint.sh /entrypoint.sh
COPY debian /action/debian

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
