#!/bin/bash

if test "$(uname -s)" = "Darwin" ; then
  xcode-select --install;
fi

mkdir -p /tmp/dotfiles
curl -L -o /tmp/dotfiles/Makefile https://raw.githubusercontent.com/tett23/dotfiles/HEAD/Makefile
make -C /tmp/dotfiles setup && make -C /tmp/dotfiles install

git clone git@github.com:tett23/dotfiles.git $HOME/dotfiles
