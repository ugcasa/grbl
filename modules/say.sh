#!/bin/bash

espeak    -p $GURU_SPEAK_PITCH \
          -s $GURU_SPEAK_SPEED \
          -v $GURU_SPEAK_LANG \
          "$@"
