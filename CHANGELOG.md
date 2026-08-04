# Changelog

All notable changes to `MimiqCircuits.jl` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.25.1] — 2026-08-05

### Docs
- Condensed the changelog entries for earlier releases.

## [0.25.0] — 2026-06-23

### Changed
- Re-export the redesigned loss API: `Loss`, `Reload`, `Check`, `MeasureCheck`, the `Lost` / `Reloaded` annotations, and `lower_losses`, with deprecation aliases for the old names.

### Build
- Bumped `MimiqCircuitsBase` compat to `0.24`.

## [0.24.2] — 2026-05-28

### Fixed
- `submit` no longer fails with `UndefVarError: WIRE_FORMAT_VERSION not defined in MimiqCircuits`.

## [0.24.1] — 2026-05-27

### Docs
- Fixed the documentation build in CI.

### CI
- GitLab Pages is now deployed only from `main`. Other pipelines still build the docs.
- The `register` job now fires only on `-private` tags, to avoid double-registering public tags.

## [0.24.0] — 2026-05-27

### Changed
- The JSON request envelope for `submit` and `optimize` now carries a `wireformatversion` key alongside `circuitsapiversion`. Older executors ignore it.

### Docs
- New `loss.md` manual page covering qubit loss, `LossModel`, and loss-aware Kraus channels.
- Added documentation for `WhileStatement`.
- Added an explanation of repeated targets / aliasing behaviour in `special_topics.md`.

### Build
- Bumped `MimiqCircuitsBase` compat to `0.23`.

## [0.23.3]

Changelog tracking begins with this version. See git history for prior changes.
