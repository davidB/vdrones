#! /bin/zsh

rm -Rf target
./build.sh --deploy
appcfg.sh  --use_java7 update target/web

