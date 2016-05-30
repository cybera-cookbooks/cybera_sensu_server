#### cybera_sensu_server 0.8.0
* Added another revere handler so that we can send alerts to both Cybera and the transition team
* Change default sensu server log level to "warn" (metrics really spammy and there doesn't seem
to be a documented way to turn them off individually)

#### cybera_sensu_server 0.6.0 (2016-03 sprint)
* added monit cookbook dependency to monitor sensu services

#### cybera_sensu_server 0.5.0 (2015-07 sprint)
* added test-checks to facilitate alert pipeline testing
* removed debugging statements that accidentally got committed
* bugfix in sensu's InfluxDB handler

#### cybera_sensu_server 0.4.0 (2015-05 sprint)
* removed dependency on the moodle monitoring cookbook
* this no longer sets up the sensu-client (leave that to a different cookbook)
