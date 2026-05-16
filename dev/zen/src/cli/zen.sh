#!/bin/bash

case $1 in
  run)
    echo "Running ZEN program: $2"
    ;;
  compile)
    echo "Compiling ZEN program: $2"
    ;;
  debug)
    echo "Debugging ZEN program: $2"
    ;;
  transpile)
    echo "Transpiling to $2: $3"
    ;;
  *)
    echo "ZEN CLI"
    echo "Commands: run, compile, debug, transpile"
    ;;
esac
