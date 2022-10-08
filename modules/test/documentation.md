# guru-client test documentation for developers

## Integration tests

To run test for all modules guru-client needs to be installed with ```-d``` argument to include developing modules.

Run ```guru test all```

See ```guru test help``` for more options.

TODO: Reports can be found at http://guru-client.ujo.guru/test/reports


## Automated unit tests

To generate tester script.

Start writing module from template ```modules/templates/shell-template.sh```

Add functions you mostly sure that you need to to communicate with user and interface with other modules.

One line function are enough to get pass, return !0 get fail.

To make test cases for 'net.sh' module by running ```modules/test/make-shell-test.sh``` with module name
TODO: without or with file ending.

- Run ```./make-shell-test.sh net```
-  Will generate ```modules/test/test-net.sh``` with test function for every function in module.
-  Run it for laugh
- ..and start to write test cases in it.


## Unit tests

Unit tests are usually run manually during module developing process.
Target is to check that all modified functions in module do work with another functions in the module, 
and with modules that it is using.
With core modules it is important check that changes do not break modules that are using it. 


**Core modules**
 
module      |result |status
------------|-------|------------------------------
mount       |       | not done
alias       |       | not done
common      |      	| not done
config      |      	| not done
core        |      	| not done
counter     |      	| not done
daemon      |      	| not done
install     |      	| not done
keyboard    |      	| not done
net         |      	| not done
os          |      	| not done
path        |      	| not done
system      |      	| not done
uninstall   |      	| not done
unmount     |      	| not done


**Modules**

module      |result |status
------------|-------|------------------------------
audio       |      	| no tester written
android		|		| 
audio		|		| 
backup		|		| 
browser		|		| 
cal			|		| 
conda		|		| 
convert		|		| 
corsair-raw	|		| 
corsair		|		| 
display		|		| 
mqtt		|		| 
news		|		| 
note		|		| 
place		|		| 
print		|		| 
program		|		| 
project		|		| 
scan		|		| 
ssh			|		| 
stamp		|		| 
tag			|		| 
telegram	|		| 
test		|		| 
timer		|		| 
tmux		|		| 
tor			|		| 
tovsdf		|		| 
trans		|		| 
tunnel		|		| 
user		|		| 
vol			|		| 
vpn			|		| 
yle			|		| 



