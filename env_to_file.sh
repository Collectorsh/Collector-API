#!/bin/bash

# Exclude some sensitive or system-specific environment variables
# Adjust the list of exclusions as needed
exclude="^(PATH|PS1|HOME|HOSTNAME|TERM|SHELL|USER|LANG|LS_COLORS|PWD|_)=.*"

# Capture all environment variables
env | grep -vE "$exclude" > .env
