#!/usr/bin/python3
import configparser
import json
import os
import sqlite3
import ssl

from paho.mqtt import publish


def get_current_stock(shop_config):
    db_file = shop_config["shop_db"]
    if not os.path.isfile(db_file):
        print("Shop db not found: %s" % db_file)
        exit(1)
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    data = []
    for row in c.execute('SELECT name, amount FROM products WHERE deprecated = 0 AND amount > 0'):
        data.append(row)

    return data


def send_to_mqtt(mqtt_config, payload):
    publish.single(mqtt_config["topic"], payload,
                   hostname=mqtt_config["host"], port=int(mqtt_config["port"]),
                   auth={'username': mqtt_config["username"], 'password': mqtt_config["password"]},
                   tls={'ca_certs': mqtt_config["host_cert"], 'tls_version': ssl.PROTOCOL_TLS, 'insecure': False},
                   client_id="send2Stock2Mqtt")


if __name__ == '__main__':
    config = configparser.ConfigParser()
    config.read("shop2mqtt.conf")

    stock_data = get_current_stock(config["shop"])
    send_to_mqtt(config["mqtt"], json.dumps(stock_data, indent=None, separators=(',', ':')))
