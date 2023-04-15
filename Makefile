os:=$(shell uname -s)
arch:=$(shell uname -m)
installer=$(shell setup/detect_package_manager.sh)

required_commands := git curl zsh fzf tmux nvim direnv
none_commands := $(strip $(foreach cmd,$(required_commands),$(if $(shell command -v $(cmd)),,$(cmd))))

.PHONY: doctor
doctor:
ifeq ($(os),Darwin)
	$(if $(shell command -v brew),$(shell true),$(shell false))
endif
ifneq (, $(none_commands))
	@echo "No $(none_commands) in $(PATH)"
	@false
else
	@true
endif

.PHONY: setup
setup:
ifeq ($(os),Darwin)
ifneq ($(shell command -v brew), "")
	@/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
endif
endif
ifneq (, $(none_commands))
	@$(installer) none_commands
endif

.PHONY: install
install:
	@git submodule update --init --recursive
	@/bin/bash -c "install.sh"
	@~/.fzf/install

.PHONY: setup-rust
setup-rust:
	$(MAKE) -C makefiles/languages/rust setup

.PHONY: setup-python
setup-python:
	$(MAKE) -C makefiles/languages/python setup
