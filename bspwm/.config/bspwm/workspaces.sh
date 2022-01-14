#!/bin/bash

export TERMINAL_DESKTOP='^1'
export FILES_DESKTOP='^2'
export EDIT_DESKTOP='^3'
export OFFICE_DESKTOP='^4'
export CHAT_DESKTOP='^5'
export MEDIA_DESKTOP='^6'
export MISC_DESKTOP='^7'
export WEB_DESKTOP='2:^1'

bspc monitor 0x00600004 -n "1" -d ''
bspc monitor 0x00600002 -n "2" -d ''
bspc monitor 0x00600004 -a '' '' '' '' '' ''
