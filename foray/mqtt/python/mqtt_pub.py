#!/usr/bin/python3

import paho.mqtt.client as paho
import time
import argparse


broker = "mqtt.ujo.guru"
sub_topic = "#"

# Initiate the parser
parser = argparse.ArgumentParser()

# Add long and short argument
parser.add_argument("--socks", "-s", help="use websocket protocol", action="store_true")
parser.add_argument("--mqtt", "-q", help="use mqtt protocol", action="store_true")
# Read arguments from the command line
args = parser.parse_args()


if args.socks:
    # create object for websocket connect method to connect mqtt
    client = paho.Client("client-socks", transport='websockets')
    port = 9001
else:
    # create object for normal mqtt connect method
    client = paho.Client("control1")
    port = 1883


# call back functions

def on_subscribe(client, userdata, mid, granted_qos):
    "create function for callback"

    print("subscribed with qos", granted_qos, "\n")
    pass


def on_message(client, userdata, message):
    print("message received ", str(message.payload.decode("utf-8")))


def on_publish(client, userdata, mid):
    "create function for callback"

    print("data published mid=", mid, "\n")
    pass


def on_disconnect(client, userdata, rc):
    print("client disconnected ok")


# assign function to callbacks
client.on_subscribe = on_subscribe
client.on_publish = on_publish
client.on_message = on_message
client.on_disconnect = on_disconnect

# establish connection
print("connecting to broker", broker, "on port", port)
client.connect(broker, port)
client.loop_start()

# subscribe
print("subscribing to ", sub_topic)
client.subscribe(sub_topic)
time.sleep(3)

# publish
client.publish("test/topic", "value")
time.sleep(4)

# close connection
client.disconnect()
