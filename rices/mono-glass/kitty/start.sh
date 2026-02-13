#!/bin/bash
count=$(pgrep -c kitty)
echo $count
# Launch main terminal
kitty --title "$count" &

# Small delay so Kitty starts before footer
sleep 1

# Launch footer window with CAVA
kitten @ launch --match "title:$count" --keep-focus bash 
