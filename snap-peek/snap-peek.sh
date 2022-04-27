#!/bin/sh
#
# snap-peek writes its impression of its world to standard out.
#
echo "I am snap-peek. I think my current directory is $PWD"
pwd=$(/bin/pwd)
echo "This might be the same as $pwd"
echo "This is who I think I am: $(whoami)"
echo "You passed the following arguments when you invoked me: $@"
echo "This is what I see in my current directory:"
ls -al --color .
echo "This is what I think my root directory contains:"
ls -a --color /
echo "This is the contents of my environment:"
env
echo "Starting a subshell..."
bash -i
