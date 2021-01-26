README.md

# mqtt connection for clients

These exsamples are made to run os lavel in debian based linux systems.

Other client methods to connect mqtt server:

- [python exsamples](python/README.md)
- [websocket, javascript and python](websocket/README.md)

## install requirements

```bash
sudo apt update
sudo apt-get install -y mosquitto-clients
```

## mqtt-open test

```bash
# subscribe to teopic /test
mosquitto_sub -h mqtt.ujo.guru -p 1883 -t /test -C 1 &
# open new terminal and send message to topic /test
mosquitto_pub -h mqtt.ujo.guru -p 1883 -t /test -m "hello open mqtt"
```

## mqtt-dev test

```bash
# subscribe to teopic /test
mosquitto_sub -h deal-dev.ujo.guru -p 22383 -t /test -C 1 &
mosquitto_pub -h deal-dev.ujo.guru -p 22383 -t /test -m "hello local ecnrypted mqtt"

# subscribe to teopic /test
mosquitto_sub -h deal-dev.ujo.guru -p 22384 -t /test -C 1 &
mosquitto_pub -h deal-dev.ujo.guru -p 22384 -t /test -m "hello encrypted mqtt with tlc certs"


```

## mqtt-test test

```bash
sudo apt-get install mosquitto-clients

# subscribe to teopic /test
mosquitto_sub -h deal-dev.ujo.guru -p 1883 -t /test &

# send message to topic /test
mosquitto_pub -h deal-dev.ujo.guru -p 1883 -t /test -m "hello mqtt!"

