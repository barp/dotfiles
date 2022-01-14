#!/bin/bash

export TERMINAL_DESKTOP='^1'
export WEB_DESKTOP='^2'
export FILES_DESKTOP='^3'
export EDIT_DESKTOP='^4'
export OFFICE_DESKTOP='^5'
export CHAT_DESKTOP='^6'
export MEDIA_DESKTOP='^7'
export MISC_DESKTOP='^8'

name=1
for monitor in $(bspc query -M); do
	#bspc monitor ${monitor} -n "$name" -d 'I' 'II' 'III' 'IV' 'V' 'VI' 'VII' 'VIII'
      (( name++ ))
      bspc monitor "${monitor}" -n "$name" -d '' '' '' '' '' '' '' ''
done
