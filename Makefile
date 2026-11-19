# shellcheck is preinstalled in GH Ubuntu image, locally: brew install shellcheck
lint:
	@shellcheck *.sh scripts/*.sh build/*.sh
