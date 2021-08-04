__open_github() {
  local path=$3
  local tid=$(git cat-file "`git rev-parse HEAD`" -p | head -1 | awk '{print $2}')
  # local cid=$(git log --pretty=oneline $path | head -n 1 | awk '{print $1}')
  echo $tid

  open "https://github.com/grooves/forkwell/tree/$tid/$path"
}

__open_github $3
