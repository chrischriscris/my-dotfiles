#!/usr/bin/env bash

if type "xrandr"; then
  for m in $(xrandr --query | rg " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload topbar &
  done
else
  polybar --reload topbar &
fi

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit

