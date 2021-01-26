readme.md
# python mqtt websocket example

https://pypi.org/project/paho-mqtt

## install basic development tools

```bash
sudo apt install python3-pip
sudo pip3 install virtualenv
```

## install example requirements to native system

```bash
pip install paho-mqtt
```

## install example requirement in virtual environment

```bash
virtualenv mqtt
source mqtt/bin/activate
pip install paho-mqtt
```

## run example

```bash
cd deal-core/client-tools/websocket/python
python mqtt_pub.py --socks

# normal mwthod can be tested by
python mqtt_pub.py --mqtt
```

----

## test results 202011190

Normal access OK

    (mqtt) casa@electra:~/git/hub/deal-core/client-tools/websocket/python$ python mqtt_pub.py --mqtt

    connecting to broker mqtt.ujo.guru on port 1883
    subscribing to  #
    subscribed with qos (0,)
    data published mid= 2
    message received  value

## Issue 20201119-1

websockets did failed to handshake

    (mqtt) casa@electra:~/git/hub/deal-core/client-tools/websocket/python$ python mqtt_pub.py --socks

    connecting to broker mqtt.ujo.guru on port 9001
    Traceback (most recent call last):
      File "try_mqtt_pub.py", line 63, in <module>
        client.connect(broker, port)
      File "/home/casa/.envs/mqtt/lib/python3.6/site-packages/paho/mqtt/client.py", line 941, in connect
        return self.reconnect()
      File "/home/casa/.envs/mqtt/lib/python3.6/site-packages/paho/mqtt/client.py", line 1112, in reconnect
        self._websocket_path, self._websocket_extra_headers)
      File "/home/casa/.envs/mqtt/lib/python3.6/site-packages/paho/mqtt/client.py", line 3580, in __init__
        self._do_handshake(extra_headers)
      File "/home/casa/.envs/mqtt/lib/python3.6/site-packages/paho/mqtt/client.py", line 3664, in _do_handshake
        raise WebsocketConnectionError("WebSocket handshake error")
    paho.mqtt.client.WebsocketConnectionError: WebSocket handshake error

**Why is not working?**

- is TLS active by default?
- No, did not find any cert/key/tls/sha related stuff in code.

