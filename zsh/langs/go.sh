if [[ -x `which go` ]]; then
  export GOPATH=$HOME/repositories
  export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
fi
