#!/bin/bash
# Pick an emoji using rofi's built-in emoji module
emoji=$(rofi -modi emoji -show emoji | head -n 1)

# Send it to the focused window via wtype
if [ -n "$emoji" ]; then
    wtype "$emoji"
fi
