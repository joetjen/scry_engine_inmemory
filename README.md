# scry_engine_inmemory

A real, kind-independent [`Scry.Core.EngineBehaviour`](https://github.com/joetjen/scry_core)
implementation over a plain in-memory Elixir term store — `fetch/2` only,
no query pushdown at all. Deliberately the simplest possible engine: the
default fixture every `scry_test_<kind>` package uses, and the concrete
proof that `Scry.Core.Executor`'s own re-verification — not the engine —
is what actually guarantees a query's result is correct.

Kind-independent by construction, like every engine in this family: it
only ever sees the `source`/`Scry.Core.Query.t()` shapes `Scry.Core.
Executor` already produces once any kind-specific vocabulary (`LAST`,
eventually `via`/`hops`, ...) has been lowered away. No backend of its
own — not for production use.

Source: <https://github.com/joetjen/scry_engine_inmemory>. Specs live in
the separate [`scry`](https://github.com/joetjen/scry) repository; the
behaviour this implements lives in
[`scry_core`](https://github.com/joetjen/scry_core).

## Usage

```elixir
conn =
  Scry.Engine.InMemory.Conn.new(%{
    ["users"] => [%{"name" => "Alice", "age" => 30}]
  })

{:ok, query} = Scry.Core.parse(~s(SELECT users WHERE age > 18 { name }))
{:ok, cursor} = Scry.Core.Executor.run(query, Scry.Engine.InMemory, conn)
rows = Scry.Core.Cursor.to_list(cursor)
# rows == [%{"name" => "Alice"}]
```

`Conn.put/3` adds more rows to an existing (or new) source after the
fact:

```elixir
conn = Conn.new() |> Conn.put(["users"], [%{"name" => "Bob", "age" => 17}])
```

## Installation

```elixir
def deps do
  [
    {:scry_engine_inmemory, "~> 0.1.0"}
  ]
end
```

## Documentation

Documentation is generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

- Released versions are published to [HexDocs](https://hexdocs.pm) once the
  package ships, at <https://hexdocs.pm/scry_engine_inmemory>.
