mise := ~/.local/bin/mise

define HELP_BODY
USAGE: make <subcommand>

SUBCOMMANDS:
  help                    Show help.
  setup                   Set up development environment.
  clean                   Clean build folder.
  env                     Show build environment.
  build                   Build.
  test                    Run tests.
  sign                    Sign executable.
  format                  Format source code.
  autocorrect             Autocorrect lint issues if possible.
  lint                    Lint source code.

endef
export HELP_BODY

help:
	@echo "$$HELP_BODY"

setup:
	curl "https://mise.run" | sh

clean:
	@$(mise) run clean

env:
	@$(mise) run env

build: env
	@$(mise) run build

test:
	@$(mise) run test

sign:
	@$(mise) run sign

format:
	@$(mise) install
	@$(mise) run format

autocorrect:
	@$(mise) install
	@$(mise) run autocorrect

lint:
	@$(mise) install
	@$(mise) run lint
