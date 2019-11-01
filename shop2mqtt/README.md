# Setup

You need the python3 paho-mqtt lib. E.g. 
```
sudo apt-get install python3-paho-mqtt
```

Create the config from the example: 
```
cp shop2mqtt.conf.example shop2mqtt.conf
```
and change the config to your needs.


# Run

Just run `./sendStock2Mqtt.py` or use cron.