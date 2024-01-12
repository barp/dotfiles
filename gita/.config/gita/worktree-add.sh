#!/bin/bash

foldername=$(basename $PWD)

mkdir -p $HOME/.workspaces

git worktree add $HOME/.workspaces/$BRANCH/$foldername -b $BRANCH
