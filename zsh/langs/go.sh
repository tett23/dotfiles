# go 本体は mise で管理。GOPATH は ghq のルートと共有する。
# go は mise activate (zshrc) の後で PATH に入るので、ここでは go の有無を確かめずに設定する (docs/adr/0045)
export GOPATH=$HOME/repositories
export PATH="$PATH:$GOPATH/bin"
