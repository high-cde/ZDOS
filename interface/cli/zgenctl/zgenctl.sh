#!/bin/bash
CMD=$1
shift

case $CMD in
  add) ./commands/add.sh "$@" ;;
  query) ./commands/query.sh "$@" ;;
  palace) ./commands/palace.sh ;;
  cortex) ./commands/cortex.sh ;;
  live) ./commands/live.sh ;;
  *)
    echo "Z‑GENESIS CLI — comandi disponibili: add, query, palace, cortex, live"
  ;;
esac
