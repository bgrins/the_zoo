#!/bin/sh

# Handle CLI commands
case "$1" in
  start|stop|pause|resume|status|reset|workers|queue|recover|cleanup)
    exec node cli.js "$@"
    ;;
  *)
    # Otherwise run the default crawler daemon with npm run dev
    exec npm run dev
    ;;
esac