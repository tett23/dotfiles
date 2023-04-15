#!/bin/sh

case $(uname -s) in
  Darwin) echo "brew install" ;;
  *) exit 1 ;;
esac
