# shellcheck is preinstalled in GH Ubuntu image, locally: brew install shellcheck
app1-lint:
	@shellcheck build/*.sh
