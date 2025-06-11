#!/bin/bash


# git submodule foreach 'git checkout main'
# git submodule foreach 'git pull'

git submodule foreach 'git add . && git commit -m "Sites updated"'
git add .
git commit -m "Update submodule references"
git submodule foreach 'git push'
git push