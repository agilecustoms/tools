# AGENTS.md

Shared rules for all agilecustoms repos. Each repo may have its own `AGENTS.md` with project specifics.
Read both, the repo one wins on conflict.

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

Targets follow one naming scheme across repos, the number is the stage:

| Target prefix         | What it does                                                         | Safe to run       |
|-----------------------|----------------------------------------------------------------------|-------------------|
| `_aws-login`          | `aws sso login` (interactive)                                        | no - ask the user |
| `app0-*`              | install / update dependencies                                        | yes               |
| `app1-*`              | lint, format, type check                                             | yes               |
| `app2-*`              | tests (unit, integration)                                            | yes               |
| `app3-*`              | build / package                                                      | yes               |
| `app4-*`              | hit real AWS: hot redeploy, invoke, delete versions, run against env | **no, never**     |
| `terraform*-*`        | `get` / `init` / `validate` / `fmt`                                  | yes               |
| `terraform*-*`        | `plan` / `apply` / `destroy` / `unlock`                              | **no, never**     |
| `x-install-git-hooks` | copies `.github/pre-commit` into `.git/hooks`                        | yes               |

Before finishing a change run the repo's lint and test targets (`app1-*`, `app2-*`).
Don't run anything that deploys, invokes or deletes in AWS, even if `ENV` looks like a non-prod default: ask the user.

Private dependencies (Maven, npm) come from AWS CodeArtifact. Locally the token comes from `~/agilecustoms/github/tools/build/tools.sh`
(`ac_build_token`), which needs an AWS SSO session. If you can't get it, say so - don't skip the step silently.

## Git / Release

- Commit prefixes: `feat:`, `fix:`, `misc:`, `docs:`, `build:`. The release version is derived from them.
- public repos released by `agilecustoms/release`, private repos released by its wrapper `agilecustoms/gha-release`:
  direct push to `main` or merge to `main` releases automatically. CI makes the
  `Release version ... [skip ci]` commits and updates `CHANGELOG.md` and versions - never do that by hand.
- `.github/pre-commit` (where present) runs the repo's linters; don't bypass it with `--no-verify`.
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
