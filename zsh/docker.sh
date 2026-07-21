function figbe() {
  figrm bundle exec "$@"
}

function figsh() {
  docker compose run --rm $1 sh
}

# 不要な image / volume がディスクを圧迫した場合の掃除用。
# compose を停止して未使用の image / volume を prune する (volume は確認なしで消えるので注意)
function remove_all_images_and_containers() {
  docker compose down
  docker image prune
  docker volume prune -f
}
