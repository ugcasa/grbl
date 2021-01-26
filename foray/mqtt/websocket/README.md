README.md
# mqtt over websockets - mosquitto

"Windows install packages still don’t have websockets.Linux package installed using apt-get currently installs mosquitto version 1.4.12 and has websockets support already complied in to it."

## mqtt-open configurations

1) connect to client-broker and  to mqtt-open configureation

```bash
shh deal@client-broker
joe /home/deal/docker/mqtt-open/config/mosquitto.conf
```
2) add unencrypted websocket listener

```
# websocket unencrypted
listener 9001
protocol websockets
```

3) reboot server and leave server

```bash
docker restart mqtt-open
exit
```

## Tying connections

- [javascript exsamples](javascript/)
- [python examples](python/)

