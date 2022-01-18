#!/bin/bash

# hint: print preprocessor
# nasm -E "$1"
  
if [ ! "$1" ]; then
        printf "You must provide asm file\n" "$0"
        exit 1
fi

obj_name=${1%.*}

nasm -f elf64 "$1" -o "$obj_name.o"
[ $? -ne 0 ] && exit 1

ld "$obj_name.o" -o  "$obj_name"
[ $? -ne 0 ] && exit 1

rm "$obj_name.o"
./"$obj_name"
