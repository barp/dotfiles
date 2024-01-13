#!/bin/bash

echo $@

foldername=$(basename $PWD)

git worktree remove $BRANCH/$foldername
