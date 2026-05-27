# Changelog

All notable changes to `MimiqCircuits.jl` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
