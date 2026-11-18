# AGENTS.md

Shared rules for all agilecustoms repos. Each repo may have its own `AGENTS.md` with project specifics.
Read both, the repo one wins on conflict.

Claude Code SessionStart hook (registered by `tools/install.sh`) runs `tools/scripts/check-for-update.sh`.
If its output says tools are out of date, tell the user that tools (incl. these rules) are out of date and offer to update
with the command it prints (`git pull` and `install.sh`)

## Repos

There are few types of repos:
- Project repos: `tt-*`, `ev-*`, `env-*` (+`envctl`) repos constitute respective projects `tt`, `ev`, `env`.
  Each project has `-gitops` repo that stores a manifest with versions of all components of this project.
- `gha-*` - private corporate GitHub Actions
- `terraform-*` - Open source Terraform modules 
- private libraries used by other projects:
  - `tf-commons` (reusable Terraform modules)
  - `java-parent` (Maven project used as parent for all java projects)
- Open source GitHub Actions:
  - `setup-maven-codeartifact`
  - `release` and its two dependencies `release-gen`, `publish-s3` (used only here) constitute a `release` GitHub Action.
- `infrastructure-core` - core infrastructure: aws organization (accounts), SSO, CodeArtifact, IAM, permission boundaries,
  GitHub repos and groups, user accounts

## GitHub workflows

Most repos are software products with semantic versioning and CI pipeline that ends with release step.
`*-gitops` repos orchestrate microservices. This is the only type of repo that has a deployment pipeline

All non-gitops repos share similar workflow structure:
- `build.yml` (name `Build`) runs on push in any branch, its `Release` job runs only on `main`
- repos with multiple release workflows have dedicated workflow files `release.yml`, `release-dev.yml` which call `build.yml` internally
- Jobs that must pass before PR merge (`Build`, `Test`, etc) are declared in `infrastructure-core/github/repo-*.tf`
- Repos that have multiple test jobs (`Input-Validation`, `E2E`) declare one final job `Test` that is used as quality gate
- Job names:
  - `Build` - standard CI flow: install deps, lint, unit tests, package
  - `Validate` - lint / static checks for infra-only repos
  - `Validate-infra` - terraform validation in repos with both code and infrastructure (microservices)
  - `Test` - integration tests
  - `Release` - runs mostly on `main` branch and calls `release` GA Action for public repos
    or `gha-release` - corporate-specific wrapper for private repos.
    `release` action uses conventional commit messages, see [Git / Release](#git--release) section below

Makefiles are used as a contract between local and CI runs, see [Makefile](#makefile) section below.
Makefile has targets `app1-lint`, `app2-test`, `app3-build/package` (numbers just give the order).
CI pipeline calls these targets in corresponding steps,
so we can modify/debug CI steps locally with high confidence that it will behave the same in CI

## Git / Release

- Commit prefixes: `feat:`, `fix:`, `misc:`, `docs:`, `build:`. The release version is derived from them.
- Direct push to `main` or merge to `main` releases automatically. CI makes the `Release version ... [skip ci]` commits
  and updates `CHANGELOG.md` and versions - never do that by hand.
- Git hooks live in `.githooks/` (where present), `.githooks/pre-commit` runs the repo's linters; don't bypass it with `--no-verify`.
  Git uses them via `core.hooksPath = .githooks`, set once per machine for all repos under `~/agilecustoms/github/`
  (`includeIf` in `~/.gitconfig`, see Confluence "Git/GitHub"). If `git config core.hooksPath` in a repo is not `.githooks`,
  tell the user, don't set it per repo
- by default, AI Agent makes all changes in working copy of `main` branch, `git add`s any new files, but does not commit them.
  Human review changes and gives commands `commit` and `push`

## Runtimes and entry points

All services (whatever the language) use concept of profiles. Often profile is just a set of properties in file
(`.yaml`, `.toml`, `.env`, etc) but can also be some code that is only activated for a specific profile.
Active profiles are passed to the application at start, usually via environment variable (`SPRING_PROFILES_ACTIVE`, `APP_PROFILES`).
Property files are merged, later wins.
Profile types:
1. default – always loaded (hence not passed in the list of active profiles)
2. environment type - `dev`, `test`, `prod` (Terraform `var.env_type`)
3. runtime – see the table
4. runtime-environment - `{runtime}-{environment}`, ex: `aws-prod`, for overrides

| runtime    | what runs where                                                                            | profiles                    |
|------------|--------------------------------------------------------------------------------------------|-----------------------------|
| `aws`      | app in Lambda                                                                              | `{env},aws,aws-{env}`       |
| `local`    | app on local machine, all dependencies local (LocalStack, DB in docker), never touches AWS | `dev,local,local-dev`       |
| `localaws` | app on local machine, real AWS resources of an env                                         | `dev,localaws,localaws-dev` |
| `openapi`  | one-time run to generate the OpenAPI spec                                                  | `openapi`                   |
| `it`       | integration tests                                                                          | `it`                        |

Entry points are siblings over the same dependency injection container (application logic is defined once):
Lambda handler (`aws`), local server (`local`, `localaws`), invoke (`local`), OpenAPI generator, integration tests.
Invoke runs the Lambda handler once with an event from a file (SQS message, API Gateway request),
prints JSON logs and the response, exits with exit code: debug a feature or replay an event w/o deploying.
Invoke details:
- the same handler code as in AWS over a root module of local config: credentials never come from AWS secrets
- a service w/o `local` runtime invokes in `localaws` (target `invoke-localaws`, ex: ev-invoice)
- the response goes to stdout as is, not as a log record; exit code 1 on error or HTTP 5xx

File names per language:
- Python `lambda_handler.py`, `local/run_local.py`, `local/invoke.py`, `openapi/`
- TypeScript `lambda_handler.ts`, `run_local.ts`, `invoke.ts`, `openapi.ts`
- Java `LambdaHandler`, `Application` (local), `Invoke`

## Makefile

Make targets:
- `_aws-login` - `aws sso login`
- `app0-*` - install / update dependencies locally (the only stage that fetches the CodeArtifact token).
  Not used in CI because CI uses specialized OIDC access and caching
- standard CI steps, intended to be the same for local and CI.
  Few exceptions say why: `app1-lint-fix: # not called by CI (local only...)`
  - `app1-*` - lint, format, type check
  - `app2-*` - tests (unit, integration)
  - `app3-*` - build/package, generate OpenAPI spec
- run application locally:
  - `run-local-deps` - local dependencies in foreground: `trap 'docker compose down -v' EXIT HUP INT TERM; docker compose up`
    (trap also stops them when the terminal is closed, `-v` removes their anonymous volumes: state isn't kept between starts)
  - `run-local` - local server in `local` runtime
  - `run-local-watch` - same with reload on code change (where the stack supports it)
  - `run-localaws` - local server in `localaws` runtime
- `invoke-local` - AI optimized entry point: run the application in `local` runtime with `EVENT=events/<name>.json`,
  capture response (plus logs) and shut down. Sample events are in `events/`
- `hot-*` - hot redeploy to AWS. A repo adds `hot-*` only where useful
- `debug-*` - debug some complex workflows
- `terraform-*` - deploy / destroy infrastructure. A repo adds `terraform-*` only where useful
- `x-*` - various helpers
- extra variants are allowed, they keep the runtime name in target name
- `*-gitops` and `infrastructure-core` have their own schemes (`env0-status`, `gh-1-plan`...): don't run them, ask the user

AI agent specific:
- AI agent runs freely: `app*`, `run-local`, `run-local-deps`, `run-local-watch`, `invoke-local`; anything else: ask first
- Before finishing a change, run the targets `app1-*` and `app2-*` (and `app3-*` if dependencies changed)
- Don't run anything that deploys, invokes or deletes in AWS, even if `ENV` looks like a non-prod default: ask the user

## Package management

Private dependencies (Maven, npm) come from AWS CodeArtifact

Locally CodeArtifact token comes from `~/agilecustoms/github/tools/build/tools.sh` (`ac_build_token`).
To generate a token an active AWS SSO session is needed. If you need a fresh artifact and the session is expired,
you must notify user and ask to run `aws sso login` to refresh the session

## Readme

README sections, same names in all services:
"Profiles", "Run locally", "Run locally with AWS resources (localaws)", "Integration tests" (only if the service has them).
"Run locally" is always there: if there is no `local` runtime, it says why (ex: no local substitute for Cognito)

## Local run

Local run can be performed from IDE or CLI. Both share same setup (profiles, env vars, dependencies):
- IDE (developer: debugger from the first line, env vars, hot reload):
  run configurations "local-deps", "local", "localaws", "invoke-local" in `.run/`
  (JetBrains "store as project file", in git; `.idea/` stays ignored)
- CLI (FE developer who just needs BE, BE developer who uses different IDE): `make run-local`, `make run-localaws`.
An IDE configuration and its make target must set the same profiles and env vars

Local dependencies are started explicitly, then the app, as two processes. `run-local-deps` always runs in foreground:
once you stop the process, the dependencies stop too. So you never get unused containers running in background.
The app checks that dependencies are ready and stops at once with a hint if they are not running or not ready

Local dependencies are in `docker-compose.yml` in repo root:
- no restart policy, no `container_name` (compose names containers by project, ex: `env-api-localstack-1`)
- a healthcheck tells when they are ready (ex: LocalStack init scripts are done),
  the app checks the same readiness at start, it takes the endpoint from its local config

## Logging (Lambdas)

Logs are JSON (`level`, `service`, `env`, `requestId`, `message`, ...); values go in fields, not only in message text.
Every Lambda that handles events or requests follows this contract, so one query covers all of them:
- One closing record per invocation, always (also on exception: `finally` / every exit path), INFO level,
  message `event handled <outcome>`. Fields: `outcome` (kebab-case) and `durationMs` (whole invocation), service-specific
  extras are fine (`status`, `stage`, `resources`...). The error itself is logged separately (ERROR with stack trace)
- `outcome` values are service-specific, except `failed`: system error (SQS retries the message, HTTP 5xx), same everywhere
- SQS-triggered: if receive count > 1, one record `retry, attempt N` with numeric `attempt` at the start
- Exempt: authorizers (they log denials, API Gateway access logs cover requests)

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
