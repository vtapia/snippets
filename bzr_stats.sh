#!/bin/bash
# Cheap bash alternative to diffstat

VERBOSE=0
if [[ $1 == "-v" ]]; then VERBOSE=1; fi

while IFS='' read -r diffline ; do
	LINE=$(echo $diffline|grep -Ev '^\-\-\-|^\+\+\+|^\@\@' | grep -E '^\+|^\-|^\=\=\=')
	if [[ ${LINE:0:3} = \=\=\= ]] ; then
		if [[ $VERBOSE -eq 1 ]]; then
			if [[ ! -z $ADD ]]; then echo "+: $ADD"; fi
			if [[ ! -z $DEL ]]; then echo "-: $DEL"; fi
			echo $LINE
			ADD=0
			DEL=0
		fi
	elif [[ ${LINE:0:1} = \+ ]] ; then
		ADD=$((${ADD}+1))
	elif [[ ${LINE:0:1} = \- ]] ; then
                DEL=$((${DEL}+1))
	fi
done
echo "+: $ADD"
echo "-: $DEL"
