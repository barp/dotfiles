#!/bin/bash

echo $@

foldername=$(basename $PWD)

mkdir -p $HOME/.workspaces

git worktree remove $BRANCH/$foldername
