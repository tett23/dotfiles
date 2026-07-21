# go 本体は mise で管理。GOPATH は ghq のルートと共有する
if command -v go >/dev/null 2>&1; then
  export GOPATH=$HOME/repositories
  export PATH="$PATH:$GOPATH/bin"
fi
