# issues, analysis, nice and bad ideas for next version


## daemon.sh - not running after user config reset

- [x] fixes it self, firstly teted in old terminal with default user.cfg


## daemon.sh - kill
- [ ] 1) 'sudu guru kill' is inpossible, guru is not installed for root.
- [ ] 2) does now kill or get wrong result 'killed..' or tester is getting wrong result and tries again
- [ ] 3) sleep to get path printed on right position

```
	casa@electra#:~$ gr daemon kill -f
	Terminated
	casa@electra#:~$ daemon killed..
	daemon still running, try to 'sudo guru kill' again

	casa@electra#:~$ gr daemon kill -f
	Terminated
	casa@electra#:~$ daemon killed..
	daemon still running, try to 'sudo guru kill' again
	...
```

## common.sh - speak synthesizer

Guru needs a voice.

**todo:**

- [x] POC is working already, try option '-s'.
- [ ] make it really work
- [ ] how to inform module to produce readable text, verbose level 5?
- [ ] needs tag/whatever 'speaker ready module' or empty output


## config.sh - rc system rewrite

Stink this trough.
It makes now no sense, it grow like that, not designed.

- [ ] core rc clean up
- [ ] learn how it works now ;D
- [ ] changes to project.sh
- [ ] changes to config.sh


## config.sh - modules can run stand alone by default

Modules need to be able to run without .gururc.
Exception is core level modules,
those have veto do shit ever they want.

**todo:**

- [x] bash -x
- [ ] .gururc is generated badly



