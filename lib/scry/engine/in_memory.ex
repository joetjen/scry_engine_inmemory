defmodule Scry.Engine.InMemory do
  @moduledoc """
  A real, kind-independent `Scry.Core.EngineBehaviour` implementation
  over a plain in-memory Elixir term store -- `fetch/2` only, no
  `fetch/3` pushdown at all. Deliberately the simplest possible engine:
  the baseline every `scry_test_<kind>` package uses for its own
  default fixture, and the concrete fixture proving `Scry.Core.
  Executor`'s own re-verification (not the engine) is what actually
  guarantees a query's result is correct -- any test passing against
  this engine is proof the query's full semantics work end to end with
  no help from the engine at all.

  Kind-independent by construction, the same way every engine in this
  family is: it only ever sees `source`/`Scry.Core.Query.t()` shapes
  `Scry.Core.Executor` already produces after any kind-specific
  vocabulary (`LAST`, eventually `via`/`hops`, ...) has been lowered
  away -- nothing here needs to know which kind's own grammar produced
  the query it's fetching for.

  Not for production use -- there's no real backend behind this at
  all, just whatever `Scry.Engine.InMemory.Conn` happens to hold.

  ## Usage

      conn =
        Scry.Engine.InMemory.Conn.new(%{
          ["users"] => [%{"name" => "Alice", "age" => 30}]
        })

      {:ok, query} = # ... parse + build a %Scry.Core.Query{}
      {:ok, cursor} = Scry.Core.Executor.run(query, Scry.Engine.InMemory, conn)
      rows = Scry.Core.Cursor.to_list(cursor)
  """

  @behaviour Scry.Core.EngineBehaviour

  alias Scry.Engine.InMemory.Conn

  @impl true
  def fetch(%Conn{data: data}, source) do
    case Map.fetch(data, source) do
      {:ok, rows} -> {:ok, rows}
      :error -> {:error, {:no_such_source, source}}
    end
  end
end
