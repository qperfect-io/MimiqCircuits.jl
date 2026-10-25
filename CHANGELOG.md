# Changelog

All notable changes to `MimiqCircuits.jl` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.26.0] — 2026-10-25

This release requires MimiqCircuitsBase 0.27, and through the re-export it brings
the features and changes of MimiqCircuitsBase 0.26 and 0.27. The main ones are
listed below; see the MimiqCircuitsBase changelog for the full list.

### Added
- Re-export `QhiveConnection`, so `connect(QhiveConnection)` opens a connection to the Quantum Hive services, which authenticate through Keycloak rather than the MIMIQ cloud login. Every other connection type behaves as before.
- `simplify(c)` reduces the gate count of a circuit while keeping its unitary exactly, global phase included. Its passes `remove_identities`, `cancel_inverses`, `merge_rotations`, `resynthesize_1q`, `resynthesize_2q` and the opt-in `resynthesize_linear` are exported too. `submit` does not simplify; simplify the circuit before submitting it.
- `ParameterTable`, `gridtable` and `SweepExperiment` describe a parameter sweep of a symbolic circuit. `submit` does not take a `SweepExperiment`; submit its evaluated circuits, `collect(ex)`, in batch mode.
- `PrepareStateT()` prepares a qubit in the magic state `T|+⟩`.
- `MeasurePauli(pauli)` measures a Pauli product observable into one classical bit.
- `pauli_based_computation(c)` rewrites a Clifford+T circuit into Pauli rotations and Pauli measurements, optionally with magic-state injection.
- `GridSynthRewrite` approximates Z rotations with Clifford+T gates, and `CliffordTBasis(; rotations=rule)` selects the rule that synthesizes them.
- `StimBasis` keeps the operations Stim 1.16 supports natively, such as `MeasurePauli`, pair measurements, Pauli rotations by ±π/2 and Pauli feedback, as terminal.
- `CliffordTBasis`, `FlattenedBasis` and `RuleBasis` decompose classically controlled operations instead of raising `DecompositionError`.

### Changed
- `submit` sends wire format 1.3.0, which adds `MeasurePauli` and `PrepareStateT` and writes symbolic parameters as exact expression trees. Jobs need an executor that speaks 1.3.0.
- `CliffordTBasis()` synthesizes arbitrary rotations with gridsynth instead of Solovay-Kitaev, and keeps the Stim operations of `StimBasis` as terminal.
- Decompositions hold exact fractions of π, such as `π/2`, instead of floating-point angles.
- `draw` packs instructions on disjoint wires into shared columns; `draw(c; compact=false)` keeps one instruction per column.
- `evaluate` returns a wrapper without free symbols unchanged and rebuilds one with free symbols through `control`, `inverse`, `power`, `parallel` and `repeat`.
- `fuse` emits its blocks in a different order; the circuit it returns has the same unitary as before.

### Deprecated
- `PrepareMagic` is a deprecated alias of `PrepareStateT`.

### Removed

The loss aliases deprecated in 0.25.0 are gone. Replace `LossErr(p)` with
`Loss(p)`, `QubitLoss()` with `Loss()`, `QubitReload()` with `Reload()`,
`CheckLoss()` with `Check()` and `MeasureCheckLoss()` with `MeasureCheck()`.
Circuits saved with the old `QubitLoss` operation still load, as `Loss()`.

- `LossErr`, `QubitLoss`, `QubitReload`, `CheckLoss` and `MeasureCheckLoss` are no longer defined.
- The `sk_depth` field of `CliffordTBasis` is removed; use `basis.rotations.depth` instead.

### Migration

`CliffordTBasis()` now approximates rotations with gridsynth, so decomposed
circuits change: they are shorter and more accurate. Pass
`CliffordTBasis(sk_depth=3)` to get the previous Solovay-Kitaev output. The
output can also contain Stim operations such as `MeasurePauli`, `PauliNoise` or
`GateRZZ(π/2)`; code that expects only elementary Clifford+T gates must expand
them itself. Read the depth of a Solovay-Kitaev basis from
`basis.rotations.depth`, since the `sk_depth` field is gone.

Decomposed circuits hold exact angles such as `π/2` where they held
`1.5707963267948966`. Code that compares their parameters with `==` against
floats should compare `unwrapvalue(p)` with `≈` instead.

### Fixed
- `getresults` reports the server's reason when a remote job errors on Quantum Hive. Its API returns a `messages` list where the MIMIQ cloud returns `errorMessage`, so the failure came back with the bare "please contact support" text.
- `submit`, `execute` and `optimize` work on a `QhiveConnection`. They use the default time limit for every connection other than the MIMIQ cloud, which reports per-user limits.

### Build
- Require `MimiqLink` 0.11, its first release with `QhiveConnection`.
- Require `MimiqCircuitsBase` 0.27.

### Docs
- `QCSError` has a docstring explaining that `getresults` returns it, rather than throwing it, for each circuit that failed.
- The `optimize` docstring shows up in the help and the API reference.
- The decompositions manual covers gridsynth in `CliffordTBasis`, its `rotations` keyword, the Stim 1.16 terminal set of `StimBasis`, and conditional operations.
- A new manual page explains `pauli_based_computation`, with and without magic-state injection.
- The non-unitary operations manual covers `MeasurePauli` and `PrepareStateT`.
- The Stim section of the import manual lists what a Stim 1.16 file may contain and what MIMIQ refuses.
- The loss manual uses `Loss`, `Reload`, `Check`, `MeasureCheck` and `resolve_losses` instead of the removed names and the removed `lossmodel` keyword of `sample_losses`.
- The API reference documents `GridSynthRewrite`, `pauli_based_computation`, `MeasurePauli`, `PrepareStateT`, `simplify` and its passes, the parameter sweep types and the loss API.
- The simplifications manual covers `simplify`, its passes and how to choose them.
- The symbolic operations manual covers parameter sweeps with `ParameterTable`, `gridtable` and `SweepExperiment`, and how to submit one.
- The examples of the DSL manual run as doctests again.
- The API reference includes `WhileStatement`, `GateCustomDiagonal`, `ToffoliToCliffordTRewrite`, `fuse`, the circuit graph traversals, the `@circuit`, `@block` and `@gatedecl` macros and the circuit tester, and lists every other docstring once.
- The special operations manual declares gates with the current `@gatedecl` syntax.
- Links to `Loss`, `Hamiltonian`, `RewriteRule` and `isterminal` in the manual resolve to their docstrings, and the citations in MimiqCircuitsBase docstrings render with a new References page.

## [0.25.2] — 2026-08-19

### Build
- Require `MimiqCircuitsBase` 0.25, which brings `GateCustomDiagonal` and the `max_diagonal_support` argument of `fuse` through the re-export.

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
