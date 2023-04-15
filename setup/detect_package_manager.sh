#!/bin/sh

case $(uname -s) in
  Darwin) echo "brew install" ;;
  Linux) echo "apt install" ;;
  *) exit 1 ;;
esac
