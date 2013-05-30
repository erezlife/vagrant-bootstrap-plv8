#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y build-essential subversion git

# install postgres
sudo apt-get install -y libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev
wget http://ftp.postgresql.org/pub/source/v9.3beta1/postgresql-9.3beta1.tar.gz
tar -xzf postgresql-9.3beta1.tar.gz
cd postgresql-9.3beta1
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

# install postsql extensions
cd ../
git clone https://github.com/tobyhede/postsql.git
sudo -u postgres /usr/local/pgsql/bin/psql -d template1 -f postsql/postsql.sql

