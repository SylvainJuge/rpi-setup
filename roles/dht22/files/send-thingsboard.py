import os
import time
import Adafruit_DHT as dht
import paho.mqtt.client as mqtt
import json

def get_env(v, default):
    m = os.environ
    if v in m:
        return m[v]
    else:
        return default

host = get_env('THINGSBOARD_HOST', 'localhost')
port = get_env('THINGSBOARD_PORT', 1883)
token = get_env('THINGSBOARD_TOKEN', 'missing token')

# Data capture and upload interval in seconds. Less interval will eventually hang the DHT22.
INTERVAL=2

sensor_data = {'temperature': 0, 'humidity': 0}

next_reading = time.time() 

client = mqtt.Client()

# Set access token
client.username_pw_set(token)

# Connect to ThingsBoard using default MQTT port and 60 seconds keepalive interval
client.connect(host, port, 60)

client.loop_start()

try:
    while True:
       humidity,temperature = dht.read_retry(dht.DHT22, 4)
       humidity = round(humidity, 2)
       temperature = round(temperature, 2)
       sensor_data['temperature'] = temperature
       sensor_data['humidity'] = humidity

        # Sending humidity and temperature data to ThingsBoard
        client.publish('v1/devices/me/telemetry', json.dumps(sensor_data), 1)

        next_reading += INTERVAL
        sleep_time = next_reading-time.time()
        if sleep_time > 0:
            time.sleep(sleep_time)
except KeyboardInterrupt:
    pass

client.loop_stop()
client.disconnect()
