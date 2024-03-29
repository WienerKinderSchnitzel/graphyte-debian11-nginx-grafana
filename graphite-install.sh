#!/bin/bash
# Debian 11 - ready

## Update System
sudo apt-get update

## Install Dependencies
sudo apt-get install python3-pip  python3-cairo python3-django --yes
sudo pip install cffi


sudo pip install -r https://raw.githubusercontent.com/graphite-project/whisper/master/requirements.txt
sudo pip install -r https://raw.githubusercontent.com/graphite-project/carbon/master/requirements.txt
sudo pip install -r https://raw.githubusercontent.com/graphite-project/graphite-web/master/requirements.txt

## Install Whisper, Carbon and Graphite
#export PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/"
export PYTHONPATH="/var/lib/graphite:/opt/graphite/webapp/"

sudo pip install --no-binary=:all: https://github.com/graphite-project/whisper/tarball/master
sudo pip install --no-binary=:all: https://github.com/graphite-project/carbon/tarball/master
sudo pip install --no-binary=:all: https://github.com/graphite-project/graphite-web/tarball/master


## Setting up Carbon
sudo cp /opt/graphite/conf/carbon.conf.example /opt/graphite/conf/carbon.conf
sudo cp /opt/graphite/conf/storage-schemas.conf.example /opt/graphite/conf/storage-schemas.conf

## Setting up Graphite Web
sudo cp /opt/graphite/webapp/graphite/local_settings.py.example /opt/graphite/webapp/graphite/local_settings.py
sudo PYTHONPATH=/opt/graphite/webapp/ django-admin migrate  --settings=graphite.settings --run-syncdb

## Setting Graphite Web App Permission
#sudo useradd -s /bin/false _graphite
#sudo chown -R _graphite:_graphite /opt/graphite/
sudo chown -R www-data:www-data /opt/graphite/

# Setting up uWSGI
sudo apt-get install uwsgi uwsgi-plugin-python3 --yes
exit 0
sudo cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/wsgi.py
cd /etc/uwsgi/apps-available/
sudo curl -O https://raw.githubusercontent.com/yesoreyeram/graphite-nginx-uwsgi/master/uWSGI/graphite
sudo ln -s /etc/uwsgi/apps-available/graphite /etc/uwsgi/apps-enabled/graphite

# Setting up nginx
sudo apt-get install nginx --yes
#sudo nano /etc/nginx/nginx.conf # Change the user to _graphite
cd /etc/nginx/sites-available/
sudo curl -O https://raw.githubusercontent.com/yesoreyeram/graphite-nginx-uwsgi/master/nginx/graphite
sudo ln -s /etc/nginx/sites-available/graphite /etc/nginx/sites-enabled/graphite

# Starting Daemons
# sudo service nginx stop &
# sudo /opt/graphite/bin/carbon-cache.py start &
# sudo /usr/bin/uwsgi  --ini /etc/uwsgi/apps-enabled/graphite --pidfile /var/run/uwsgi.pid &
# sudo service nginx start &

# Install Supervisor
sudo service nginx stop &
sudo apt-get install supervisor --yes
cd /etc/supervisor/conf.d/
sudo curl -O https://raw.githubusercontent.com/yesoreyeram/graphite-nginx-uwsgi/master/supervisor/supervisord.conf
sudo service supervisor restart

# Validating the installation
echo "foo.bar 1 `date +%s`" | nc localhost 2003
ls /opt/graphite/storage/whisper/
curl "localhost:8888"
curl "localhost:8888/render/?format=json&target=foo.bar&from=-10minutes"
