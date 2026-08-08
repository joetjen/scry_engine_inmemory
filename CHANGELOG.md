# Changelog

## [Unreleased]

### Changed

- **Breaking**: `Scry.Engine.InMemory` implements `Scry.Core.EngineBehaviour`'s new `execute/3` callback instead of `fetch/2` -- the `fetch/2,3,4`/`aggregate/5` contract it used to implement is gone from `scry_core` entirely (`scry_core`'s own `CHANGELOG.md` has the full reasoning). `execute/3` receives the whole query (`WITH` bindings, nested/correlated `SELECT`, `UNION`/`INTERSECT`/`EXCEPT` combinators included) and delegates it straight to `Scry.Core.QueryOps.run_document/4`, which recurses back into this same module for each flat leaf, which in turn hands that leaf's own already-fetched rows to `Scry.Core.QueryOps.run_flat/3` -- for a plain Elixir term store with no native query language of its own, that's not a lesser implementation than a "real" translation, it's the only translation there is to do. An unknown source now surfaces as `{:error, {:query_error, {:no_such_source, source}}}` (the new, two-constructor `Scry.Core.EngineBehaviour.error/0` shape), not a bare `{:error, {:no_such_source, source}}`.

### Added

- Initial release: `Scry.Engine.InMemory` -- a real, kind-independent `Scry.Core.EngineBehaviour` implementation over a plain in-memory Elixir term store. Deliberately the simplest possible engine, extracted from what `scry_test_engine_core`'s own in-memory engine already was, so every `scry_test_<kind>` package can depend on one shared implementation instead of reimplementing the same tiny `Map.fetch/2` module once per kind. Doubles as the concrete fixture proving `Scry.Core.QueryOps`'s own toolkit is what actually guarantees a query's result is correct, not any engine-side translation.
- `Scry.Engine.InMemory.Conn` -- the connection struct `execute/3` reads from: `new/1` (a plain `%{source => rows}` map, empty by default), `put/3` (appends more rows to an existing source, or creates one).
