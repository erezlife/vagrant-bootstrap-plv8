#!/usr/bin/env bash

if [ ! -f ~/.runonce ]; then
  sudo apt-get update
  sudo apt-get install -y build-essential subversion git vim

  # install postgres
  sudo apt-get install -y libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev
  wget http://ftp.postgresql.org/pub/source/v9.3beta2/postgresql-9.3beta2.tar.gz
  tar -xzf postgresql-9.3beta2.tar.gz
  cd postgresql-9.3beta2
  ./configure
  make
  sudo make install

  sudo adduser --disabled-password  -gecos "" postgres
  sudo mkdir /usr/local/pgsql/data
  sudo mkdir /usr/local/pgsql/logs
  sudo chown postgres /usr/local/pgsql/data
  sudo chown postgres /usr/local/pgsql/logs
  #/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data
  sudo -u postgres /usr/local/pgsql/bin/initdb --locale=en_US.UTF-8 --encoding=UNICODE -D /usr/local/pgsql/data
  #/usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data >logfile 2>&1 &

  # prepare postgres for incoming data connections from host
  sudo -u postgres sed '85ihost all all 0.0.0.0/0 trust' /usr/local/pgsql/data/pg_hba.conf | sudo tee /usr/local/pgsql/data/pg_hba.conf > /dev/null
  sudo -u postgres sed "59ilisten_addresses = \'*\'" /usr/local/pgsql/data/postgresql.conf | sudo tee /usr/local/pgsql/data/postgresql.conf > /dev/null

  sudo -u postgres /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l /usr/local/pgsql/logs/pgsql.log start

  #/usr/local/pgsql/bin/createdb test
  #/usr/local/pgsql/bin/psql test
  #sudo -u postgres echo PATH=/usr/local/pgsql/bin:$PATH >> ~/.bashrc
  sudo su postgres -c "echo PATH=/usr/local/bin:$PATH >> ~/.bashrc"
  echo PATH=/usr/local/pgsql/bin:$PATH >> ~/.bashrc
  source ~/.bashrc

  # install v8
  cd ../
  svn checkout http://v8.googlecode.com/svn/trunk/ v8
  cd v8
  make dependencies
  make native library=shared
  sudo cp out/native/lib.target/libv8.so /usr/lib

  # install plv8
  cd ../
  git clone https://code.google.com/p/plv8js/
  cd plv8js
  make V8_SRCDIR=../v8/ PG_CONFIG=/usr/local/pgsql/bin/pg_config
  sudo make install PG_CONFIG=/usr/local/pgsql/bin/pg_config

  # instantiate plv8 extension
  sudo -u postgres /usr/local/pgsql/bin/psql -d template1 -c "CREATE EXTENSION plv8;"

  # install pgcrypto
  cd ../postgres-9.3beta2/contrib/pgcrypto
  make
  sudo make install

  # instantiate pgcryto extension
  sudo -u postgres /usr/local/pgsql/bin/psql -d template1 -c "CREATE EXTENSION pgcrypto;"

  # install postsql extensions
  cd ../
  git clone https://github.com/tobyhede/postsql.git
  sudo -u postgres /usr/local/pgsql/bin/psql -d template1 -f postsql/postsql.sql
  touch ~/.runonce
else
  sudo -u postgres /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l /usr/local/pgsql/logs/pgsql.log start
fi
