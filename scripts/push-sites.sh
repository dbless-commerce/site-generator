#!/bin/bash

git submodule foreach 'git add . && git commit -m "Sites updated"'
git commit -m "Update submodule references"
git submodule foreach 'git push'
git push