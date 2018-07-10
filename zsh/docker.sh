alias fig='docker-compose'

function figrm() {
  docker-compose run --rm app "$@"
}

function figbe() {
  figrm bundle exec "$@"
}

# 不要なimageであまりにディスクを圧迫した場合などに便利です。
# ただ、ローカルでforkwellの全てのimage, volumeやcontainerが削除されますので使用にはご注意を
function remove_all_images_and_containers() {
  docker-compose down
  docker image prune
  docker volume prune -f
}
