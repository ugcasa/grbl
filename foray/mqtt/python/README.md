readme.md
# python mqtt example

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

## run

```bash
cd deal-core/client-tools/python
python mqtt_pub.py
```


