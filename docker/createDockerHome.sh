#!/bin/bash

echo "This script will create dir, which shared with container home"

if [ "$1" != "" ]; then
    HOME_NAME=$1
    echo "home name is $HOME_NAME"
else
    echo "Please input home_name for root to create sub dir..."
    echo "For example: ./createDockerHome.sh dockerHome"
    exit 0
fi

echo "Create Dir..."
mkdir -p ./$HOME_NAME/mysql
mkdir -p ./$HOME_NAME/webA
mkdir -p ./$HOME_NAME/webN
mkdir -p ./$HOME_NAME/webapps/ROOT
mkdir -p ./$HOME_NAME/jarlib/.m2/
mkdir -p ./$HOME_NAME/codebase

echo "Created!"
exit 0
