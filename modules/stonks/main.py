#!/usr/bin/python3
# -*- coding: utf-8 -*-

from system import system_check
from window import window

version='0.0.1'
# class main():

# 	def __init__():
# 		pass


os = system_check()

if os.compatible != True:
	print("non compatible platform '"+os.name+"'")
	quit()

print("platform '"+os.name+"' folder separator '"+os.separator+"'")

hello_screen = window("budget manager v"+version, geometry="800x400")
hello_screen.welcome()

print("post")
