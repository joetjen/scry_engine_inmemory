defmodule Scry.Engine.InMemory.Conn do
  @moduledoc """
  The "connection" `Scry.Engine.InMemory.execute/3` reads from -- not a
  real connection at all, just whatever static dataset a caller
  supplies. Named `Conn` anyway, matching the connection/config struct
  every real adapter exposes, so code written against
  this engine reads the same way it would against a real one.

  `new/1` starts from whatever you hand it (empty by default); `put/3`
  adds more rows to an existing source (or creates one) afterward.
  There's no indexing, no query awareness, nothing beyond a plain
  `%{source => rows}` map -- see `Scry.Engine.ETS`/`Scry.Engine.
  Exqlite` for engines that actually translate part of a query into
  their own backend's native query language from inside `execute/3`.
  """

  @typedoc "Keyed by source path (e.g. `[\"orders\"]`), matching `Scry.Core.Query.source`."
  @type data :: %{optional([String.t()]) => [Scry.Core.EngineBehaviour.row()]}

  @type t :: %__MODULE__{data: data()}

  defstruct data: %{}

  @doc "Builds a `Conn` from a plain `%{source_path => rows}` map -- empty by default."
  @spec new(data()) :: t()
  def new(data \\ %{}) when is_map(data), do: %__MODULE__{data: data}

  @doc """
  Appends `rows` to whatever `source` already holds (or creates it, if
  this is the first row seen for that source).
  """
  @spec put(t(), [String.t()], [Scry.Core.EngineBehaviour.row()]) :: t()
  def put(%__MODULE__{data: data} = conn, source, rows) when is_list(rows) do
    %{conn | data: Map.update(data, source, rows, &(&1 ++ rows))}
  end
end
