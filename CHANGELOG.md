# Changelog

## [1.1.5](https://github.com/agilecustoms/tools/compare/v1.1.4...v1.1.5) (2026-11-14)

### Documentation

* run-local-deps removes anonymous volumes (down -v), README section Run locally ([54c1da8](https://github.com/agilecustoms/tools/commit/54c1da883ddb985335457478fd36412470330dcf))


## [1.1.4](https://github.com/agilecustoms/tools/compare/v1.1.3...v1.1.4) (2026-11-13)

### Documentation

* local dependencies in compose w/o container_name, readiness check reads endpoint from config, line breaks ([4ce7e64](https://github.com/agilecustoms/tools/commit/4ce7e64ba6b8239e43a0a8409e15079044eb6e38))
* local dependencies started explicitly in foreground, app checks them at start, IDE configs local-deps/local/localaws ([101d314](https://github.com/agilecustoms/tools/commit/101d3149902cd737838b108d8ebfbbfd340e862f))


## [1.1.3](https://github.com/agilecustoms/tools/compare/v1.1.2...v1.1.3) (2026-11-13)

### Documentation

* local run via IDE run configurations (.run/) and CLI make targets, run-local-deps, compose healthcheck, run_local file names ([808146c](https://github.com/agilecustoms/tools/commit/808146c657d19db49023d747e7c4b086b68af581))


## [1.1.2](https://github.com/agilecustoms/tools/compare/v1.1.1...v1.1.2) (2026-11-13)

### Documentation

* runtimes and entry points spec for all services (runtimes, entry points, make targets, README sections) ([410fea1](https://github.com/agilecustoms/tools/commit/410fea1f2ab73b95a2136fb3fd79da7d3848b69f))


## [1.1.1](https://github.com/agilecustoms/tools/compare/v1.1.0...v1.1.1) (2026-11-11)

### Documentation

* core.hooksPath is set once per machine (includeIf), not per repo [skip ci] ([8924316](https://github.com/agilecustoms/tools/commit/892431621a056a46c6c39fcba4aebba598aedcad))
* git hooks live in .githooks, enabled by core.hooksPath [skip ci] ([6f0e459](https://github.com/agilecustoms/tools/commit/6f0e459064dee86bbff3d5a51ab64d1562933d9b))

### Miscellaneous

* logging contract for Lambdas: closing record 'event handled <outcome>' with outcome and durationMs ([070c4d5](https://github.com/agilecustoms/tools/commit/070c4d5c26a00e4452cbe59a737b5213b12b8d0d))


## [1.1.0](https://github.com/agilecustoms/tools/compare/v1.0.2...v1.1.0) (2026-11-01)

### Features

* install.sh links shared AGENTS.md and registers Claude Code SessionStart hook to check for tools update ([0fb0e71](https://github.com/agilecustoms/tools/commit/0fb0e710317e7353515f45ef2a2fc8e71d333e6a))


## [1.0.2](https://github.com/agilecustoms/tools/compare/v1.0.1...v1.0.2) (2026-11-01)

### Dependencies update

* Makefile with app1-lint (shellcheck), called by CI ([fb2e46b](https://github.com/agilecustoms/tools/commit/fb2e46bd18feffbc1a8be47d0bb21e8aba9ca229))

### Documentation

* AGENTS.md GitHub workflows section (.yml files, Input-Validation) ([c0b577a](https://github.com/agilecustoms/tools/commit/c0b577a907572a0108e19479821a0f58aba82cae))


## [1.0.1](https://github.com/agilecustoms/tools/compare/v1.0.0...v1.0.1) (2026-11-01)

### Documentation

* AGENTS.md Makefile naming (run-, hot-, debug-, x-), app1-3 called from CI, GitHub workflows conventions ([6146fb1](https://github.com/agilecustoms/tools/commit/6146fb1c585c7257a3722dcf330761dddba6e7be))

### Miscellaneous

* rename Verify job to Validate [skip ci] ([b198965](https://github.com/agilecustoms/tools/commit/b198965d2400adec6976670b1d2501f33dcd3213))


# Changelog

## 1.0.0 (2026-11-01)

### Documentation

* add shared AGENTS.md for agilecustoms repos ([9dbfee3](https://github.com/agilecustoms/tools/commit/9dbfee3e6753a7128e623c02e46eb58f53a8d855))
* use tools/build/tools.sh instead of moved ~/agilecustoms/ac-tools.sh [skip ci] ([581b294](https://github.com/agilecustoms/tools/commit/581b294251f2fa3efd7ed216446f8d9aaccd6f93))

### Features

* ac_build_token takes optional AWS profile, reports failure under set -e [skip ci] ([f7b77c3](https://github.com/agilecustoms/tools/commit/f7b77c32f37d7e602f6ab7a9e10a816598dd247f))
* add build workflow (shellcheck + release) ([dbb1302](https://github.com/agilecustoms/tools/commit/dbb1302e2584a8c35166410ab1c38681674976a9))
* add build/tools.sh with ac_build_token (CodeArtifact token for local builds) ([f45b5ef](https://github.com/agilecustoms/tools/commit/f45b5ef20fce4cd92dd1bfc5fd38990a87295157))

### Miscellaneous

* add .gitignore [skip ci] ([985fe72](https://github.com/agilecustoms/tools/commit/985fe72746cb689f0bc54f2228cba0e1d39b21e2))