mise := ~/.local/bin/mise

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
