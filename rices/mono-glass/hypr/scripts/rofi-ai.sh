#!/usr/bin/env bash
# Get input from Rofi
prompt=$(rofi -dmenu -p "Ask AI:")
# If user cancels, exit
[ -z "$prompt" ] && exit

# Call Python script
answer=$(~/Coding/Spotlight-AI/venv/bin/python ~/Coding/Spotlight-AI/gpt-5-nano.py "$prompt")

# Show answer in a second Rofi window
echo "$answer" | rofi -dmenu -p "Answer"