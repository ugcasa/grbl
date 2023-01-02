#!/usr/bin/python3
# -*- coding: utf-8 -*-

from sys import platform

class system_check():
# https://docs.python.org/3/library/sys.html#sys.platform

    def __init__(self):

        self.separator='\\'
        self.name=""
        self.compatible=True

        if platform.startswith('linux'):
            self.name="linux"

        elif platform.startswith('darwin'):
            self.name="osx"

        elif platform.startswith('win32'):
            self.separator='/'
            self.name="windows"
        else:
            self.name='non-compatible'
            self.compatible=False


