Guru io connector client 
-------------------------

![tricon.png](./icons/giocon-150px.png)

[giocon](https://bitbucket.org/account/user/ugdev/projects/GIOC) 
is tool kit to o connect ujo.guru computers through the mobile barriers. 

Here's client end control menu. 

Cause *giocon.client* will be used with terminal and aim is to make usage child easy, text based menu interface with command line argument control selected as user intercase. 

Based on [Freesi diagnostics](https://bitbucket.org/freesi/diagnostics)

Clone giocon client: `git clone https://ujoguru@bitbucket.org/ugdev/giocon.client.git`


----

## Use case 1

Hostname `esteban` want's remote connection to device connected by mobile network. 

Connect to calling computer if:

- http://lassila.ujo.guru:8080 weberver gets parameter `?ssh=esteban` (php/java style)
- MQTT topic `lassila/estella/ssh-reverse` has value `esteban`  (as in "diagnostic")
- SMS "ssh esteban" to phone connected to same network 

