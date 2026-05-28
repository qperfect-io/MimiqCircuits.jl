# Changelog

All notable changes to `MimiqCircuits.jl` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.24.2] — 2026-05-28

### Fixed
- `submit` no longer dies with `UndefVarError: WIRE_FORMAT_VERSION
  not defined in MimiqCircuits`. The reference in
  `execute.jl` is now qualified as
  `MimiqCircuitsBase.WIRE_FORMAT_VERSION` so it doesn't rely on the
  `@reexport using MimiqCircuitsBase` chain resolving the symbol
  in MimiqCircuits's own namespace at runtime.

## [0.24.1] — 2026-05-27

### Fixed
- `docs/make.jl` now passes `repo=` to `makedocs` so doc builds
  succeed in GitLab CI where the shallow checkout has no `origin`
  set (Documenter no longer auto-detects).

### CI
- GitLab Pages is now deployed only from `main`, with no version
  path-prefix or per-version environment (the runner host doesn't
  support parallel deployments). `devel` and merge-request pipelines
  still build the docs in a new `docs` job in the `test` stage so a
  broken build trips the pipeline, but they no longer try to publish.
- The GitLab `register` job now fires only on `-private` tags. The
  bare public `vX.Y.Z` tag is registered into QPerfectRegistry by
  the GitHub Actions workflow on the public remote; the previous
  rule attempted both and could double-register.
- Replaced the `GIT_CONFIG_*` env-var approach for the insteadOf
  rewrites with `git config --global --add` to match the other
  Julia repos and avoid env-inheritance surprises in CI.

## [0.24.0] — 2026-05-27

### Changed
- The JSON request envelope for `submit` and `optimize` now carries a
  `wireformatversion` key (the value of
  `MimiqCircuitsBase.WIRE_FORMAT_VERSION`) alongside the existing
  `circuitsapiversion`. Executors aware of the new field will use it
  for compatibility checks; older executors ignore it.

### Docs
- New `loss.md` manual page covering qubit loss, `LossModel`, and
  loss-aware Kraus channels; linked from the noise manual.
- Added documentation for `WhileStatement`.
- Added an explanation of repeated targets / aliasing behavior in
  `special_topics.md`, with a short cross-reference from `circuits.md`.
- Removed unsupported Markdown constructs that did not render correctly
  under Documenter.

### Build
- Bumped `MimiqCircuitsBase` compat to `0.23`.

## [0.23.3]

Changelog tracking begins with this version. See git history for prior changes.
