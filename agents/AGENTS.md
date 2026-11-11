# AGENTS.md

Shared rules for all agilecustoms repos. Each repo may have its own `AGENTS.md` with project specifics.
Read both, the repo one wins on conflict.

Claude Code SessionStart hook (registered by `tools/install.sh`) runs `tools/scripts/check-for-update.sh`.
If its output says tools are out of date, tell the user that tools (incl. these rules) are out of date and offer to update
with the command it prints (`git pull` and `install.sh`)

## Repos

There are few types of repos:
- Project repos: `tt-*`, `ev-*`, `env-*` (+`envctl`) repos constitute respective projects `tt`, `ev`, `env`.
  Most of these repos are microservices released using semantic versioning.
  Each project has `-gitops` repo that stores a manifest with versions of all components of this project.
  `-gitops` has no binary releases, it is the only project repo that has a deployment pipeline.
- `gha-*` - private corporate GitHub Actions
- `terraform-*` - Open source Terraform modules 
- private libraries used by other projects:
  - `tf-commons` (reusable Terraform modules)
  - `java-parent` (Maven project used as parent for all java projects)
- Open source GitHub Actions:
  - `setup-maven-codeartifact`
  - `release` and its two dependencies `release-gen`, `publish-s3` constitute a `release` GitHub Action used by all other repos.
    (private repos use corporate-specific wrapper `gha-release`)  
- `infrastructure-core` - core infrastructure: aws organization (accounts), SSO, CodeArtifact, IAM, permission boundaries,
  GitHub repos and groups, user accounts

## Makefile

Targets follow one naming scheme across repos. In `appN-*` the number is the order you need them in

| Target        | What it does                                                                           |
|---------------|----------------------------------------------------------------------------------------|
| `_aws-login`  | `aws sso login` (interactive)                                                          |
| `app0-*`      | install / update dependencies; the only stage that fetches the CodeArtifact token      |
| `app1-*`      | lint, format, type check                                                               |
| `app2-*`      | tests (unit, integration)                                                              |
| `app3-*`      | build, package, generate OpenAPI spec                                                  |
| `run-*`       | run the app locally (`run-local`, `run-local-dev`) or against a real env (`run-aws-*`) |
| `hot-*`       | hit real AWS: hot redeploy, invoke deployed Lambda, need confirmation to run           |
| `x-*`         | various helpers, only human can run                                                    |
| `terraform-*` | need confirmation when run deploy or destroy                                           |
| `debug-*`     | debug some complex workflows, only human can run                                       |

- `app1-*` - `app3-*` represent standard stages of CI pipeline: lint, test, build/package. Numbers represent the order.
  Intended to be the same for local and CI. Few exceptions say why: `app1-lint-fix: # not called by CI (local only...)`
- `*-gitops` and `infrastructure-core` have their own schemes (`env0-status`, `gh-1-plan`...): don't run them, ask the user

Before finishing a change run the repo's lint and test targets (`app1-*`, `app2-*`).
Don't run anything that deploys, invokes or deletes in AWS, even if `ENV` looks like a non-prod default: ask the user.

## GitHub workflows

- `build.yml` (name `Build`) runs on push in any branch, its `Release` job runs only on `main`
- repos with multiple release workflows have dedicated workflow files `release.yml`, `release-dev.yml` which call `build.yml` internally
- Jobs that must pass before PR merge (`Build`, `Test`, etc) are declared in `infrastructure-core/github/repo-*.tf`
- Repos that have multiple test jobs (`Input-Validation`, `E2E`) declare one final job `Test` that is used as quality gate
- Job names:
  - `Build` - standard CI flow: install deps, lint, unit tests, package
  - `Validate` - lint / static checks for infra-only repos
  - `Validate-infra` - terraform validation in repos with both code and infrastructure (microservices)
  - `Test` - integration tests
  - `Release` - release job, runs mostly on `main` branch

Private dependencies (Maven, npm) come from AWS CodeArtifact. Locally the token comes from `~/agilecustoms/github/tools/build/tools.sh`
(`ac_build_token`), which needs an AWS SSO session. If you can't get it, say so - don't skip the step silently.

## Git / Release

- Commit prefixes: `feat:`, `fix:`, `misc:`, `docs:`, `build:`. The release version is derived from them.
- public repos released by `agilecustoms/release`, private repos released by its wrapper `agilecustoms/gha-release`:
  direct push to `main` or merge to `main` releases automatically. CI makes the `Release version ... [skip ci]` commits
  and updates `CHANGELOG.md` and versions - never do that by hand.
- Git hooks live in `.githooks/` (where present), `.githooks/pre-commit` runs the repo's linters; don't bypass it with `--no-verify`.
  When you first work with a repo that has `.githooks/`, check `git config core.hooksPath`: if it is not `.githooks`, run
  `git config --local core.hooksPath .githooks`
- by default, you make all changes in working copy of `main` branch, `git add` any new files, but do not commit them.
  Human review changes and gives commands `commit` and `push`

## Code style

Source of truth: `~/git/coding-rules`. The rules most often relevant:

- Errors: wrap with context, keep the cause (`%w` in Go, `{ cause }` in JS, `raise ... from` in Python, cause arg in Java).
  Don't log and rethrow the same error; where an error is finally handled, log it with the stack trace
  (always before returning 500). Keep one throwing call per `try` block, so the message tells which call failed.
- No code location (`[InvoiceService] ...`) in error or log messages: stack trace and logger name carry it.
- Pass context (user, request data) down as parameters; no globals / thread locals like `Request.getCurrentUser()`.
- Don't compute values before a guard clause that may return.
- Guard clauses first, happy path last; return early instead of `else` around main logic.
- A function is placed above the functions it calls.
- Lines up to ~150 chars; don't wrap earlier. Extract a variable instead of wrapping a long call.
- Single quotes for strings in JS/TS and Python.
- Return empty collections, not null. Most restrictive visibility; don't widen it for tests.
- No HTTP statuses or request objects in the service layer: map business exceptions to statuses in the controller.
- Comments explain *why*, keep the density of the surrounding code, don't add obvious ones.
  No period at the end of a comment; drop doc tags for parameters with nothing to say.
