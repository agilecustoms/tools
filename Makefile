# shellcheck is preinstalled in GH Ubuntu image, locally: brew install shellcheck
app1-lint:
	@shellcheck *.sh scripts/*.sh build/*.sh
