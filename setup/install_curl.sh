#!/bin/sh

if test "$(uname -s)" = "Darwin" ; then
  xcode-select --install ;
fi

