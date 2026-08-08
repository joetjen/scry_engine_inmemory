defmodule Scry.Engine.InMemory do
  @moduledoc """
  A real, kind-independent `Scry.Core.EngineBehaviour` implementation
  over a plain in-memory Elixir term store -- no native query language
  of its own to translate anything into. Deliberately the simplest
  possible engine: the baseline every `scry_test_<kind>` package uses
  for its own default fixture, and the concrete fixture proving `Scry.
  Core.QueryOps`'s own toolkit (not any engine-side cleverness) is what
  actually guarantees a query's result is correct -- any test passing
  against this engine is proof the query's full semantics work end to
  end with no translation help at all.

  `execute/3` delegates the *entire* query -- `WITH` bindings, nested/
  correlated `SELECT`, combinators included -- to `Scry.Core.QueryOps.
  run_document/4`, which recurses back into this same module for each
  flat leaf, which in turn hands the leaf's own already-fetched rows to
  `Scry.Core.QueryOps.run_flat/3`. This isn't "cheating" relative to
  `Scry.Core.EngineBehaviour`'s own authoritative-engine contract: for
  a plain Elixir term store with no backend query language of its own
  to speak of, "compile a query against the backend" and "run the
  toolkit over the list" are definitionally the same operation.

  Kind-independent by construction, the same way every engine in this
  family is: it only ever sees `Scry.Core.Query.t()`/`Scry.Core.
  CombinedQuery.t()` shapes `Scry.Core.Executor` already produces after
  any kind-specific vocabulary (`LAST`, eventually `via`/`hops`, ...)
  has been lowered away -- nothing here needs to know which kind's own
  grammar produced the query it's executing.

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

  alias Scry.Core.{CombinedQuery, Query, QueryOps}
  alias Scry.Engine.InMemory.Conn

  @impl true
  def execute(conn, %CombinedQuery{} = combined, params),
    do: QueryOps.run_document(conn, combined, params, __MODULE__)

  def execute(%Conn{data: data} = conn, %Query{source: source} = query, params) do
    if Enum.any?(query.select, &match?(%Query{}, &1)) or with_bound_source?(query) do
      QueryOps.run_document(conn, query, params, __MODULE__)
    else
      case Map.fetch(data, source) do
        {:ok, rows} -> QueryOps.run_flat(rows, query, params)
        :error -> {:error, {:query_error, {:no_such_source, source}}}
      end
    end
  end

  # A single-segment source naming a declared `WITH` binding has no
  # real existence in `data` at all -- `QueryOps.run_document/4` is
  # what resolves it (fresh, every reference, no caching), not this
  # module directly.
  defp with_bound_source?(%Query{source: [name], with_bindings: with_bindings}),
    do: Map.has_key?(with_bindings, name)

  defp with_bound_source?(_query), do: false
end
