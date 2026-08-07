# Changelog

## [Unreleased]

### Added

- Initial release: `Scry.Engine.InMemory` -- a real, kind-independent `Scry.Core.EngineBehaviour` implementation over a plain in-memory Elixir term store. `fetch/2` only, no `fetch/3` query pushdown at all -- deliberately the simplest possible engine, extracted from what `scry_test_engine_core`'s own in-memory engine already was, so every `scry_test_<kind>` package can depend on one shared implementation instead of reimplementing the same ~15-line `Map.fetch/2` module once per kind. Doubles as the concrete fixture proving `Scry.Core.Executor`'s own re-verification is what actually guarantees a query's result is correct, not the engine.
- `Scry.Engine.InMemory.Conn` -- the connection struct `fetch/2` reads from: `new/1` (a plain `%{source => rows}` map, empty by default), `put/3` (appends more rows to an existing source, or creates one).
