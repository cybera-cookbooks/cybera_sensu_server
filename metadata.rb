maintainer       'Cybera'
maintainer_email 'devops@cybera.ca'
license          'All rights reserved'
name             'cybera_sensu_server'
description      'Installs/Configures a sensu server for Cybera'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.6.0' # Sprint 03/2016

recipe "default",         ""

depends "sensu"
depends "uchiwa"
depends "nginx"
depends "poise-monit"
