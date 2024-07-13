mise := ~/.local/bin/mise

setup:
	curl "https://mise.run" | sh
	@$(mise) install

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
	@$(mise) run format

autocorrect:
	@$(mise) run autocorrect

lint:
	@$(mise) run lint
