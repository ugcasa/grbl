### mqtt websocket interface for javascript web applications

- good instructions http://www.steves-internet-guide.com/mqtt-websockets/
- examples http://www.steves-internet-guide.com/download/javascript-websockets/

Thanks for Steve Cope who provided demo code www.steves-internet-guide.com

## Testing open mqtt connection

To test this on your browser follow instructions below.

1) go to folder `deal-core/client-tools/websocket/javascript` and open 'websockets-4.htm' with browser or [click here](websockets-3.htm):

```bash
firefox websockets-3.htm
```
2) fill boxes as below and press Connect. Check that connection status changes
```
server: mqtt.ujo.guru
port: 9001
```
3) fill 'Subscribe Topic' box with `test` : test boxes as below and press 'Subscribe' :

4) write message and set topic same as 'Subscribe Topic' then press 'Submit'.

5) Message should appear on end of page.


## Testing encrypted mqtt connection


1) go to folder `deal-core/client-tools/websocket/javascript` and open 'websockets-4.htm' with browser or [click here](websockets-4.htm):

```bash
firefox websockets-4.htm
```
2) fill boxes below and press Connect. Check that connection status changes (ask from Deal Comp development for password and user name)
```
Server: deal-dev.ujo.guru
Port: 22392
Password:
Username:
```
3) fill 'Subscribe Topic' box with `test` : test boxes as below and press 'Subscribe' :

4) write message and set topic same as 'Subscribe Topic' then press 'Submit'.

5) Message should appear on end of page.

Quality of service can also set with this code.


## Admin view of mqtt messages on browser

TODO: show_topic.htm - web based administrative raw mqtt topic viewer


