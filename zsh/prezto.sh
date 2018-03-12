setopt EXTENDED_GLOB
for rcfile in "${DOTIFLES}"/prezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${DOTFILES}/prezto/.${rcfile:t}"
done
