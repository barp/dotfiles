#!/bin/bash

foldername=$(basename $PWD)

mkdir -p $HOME/.workspaces

git worktree remove $BRANCH/$foldername
