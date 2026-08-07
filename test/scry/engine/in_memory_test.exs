defmodule Scry.Engine.InMemoryTest do
  @moduledoc """
  `Scry.Engine.InMemory` -- confirms `fetch/2` behaves exactly like the
  in-memory engines this package is extracted from (a known source
  returns its rows, an unknown one is a clear `{:error, ...}`, never a
  raise), and that it composes end to end with a real `Scry.Core.
  Executor.run/4` call -- not just in isolation against `fetch/2`
  directly.
  """

  use ExUnit.Case, async: true

  alias Scry.Core.{Cursor, Executor, Query}
  alias Scry.Engine.InMemory
  alias Scry.Engine.InMemory.Conn

  describe "fetch/2" do
    test "returns the rows for a known source" do
      conn = Conn.new(%{["users"] => [%{"name" => "Alice"}]})

      assert InMemory.fetch(conn, ["users"]) == {:ok, [%{"name" => "Alice"}]}
    end

    test "returns a clear error for an unknown source, never raises" do
      conn = Conn.new(%{["users"] => []})

      assert InMemory.fetch(conn, ["orders"]) == {:error, {:no_such_source, ["orders"]}}
    end
  end

  describe "end to end through Scry.Core.Executor.run/4" do
    test "a plain filter executes correctly against this engine" do
      conn =
        Conn.new(%{
          ["users"] => [
            %{"name" => "Alice", "age" => 30},
            %{"name" => "Bob", "age" => 17}
          ]
        })

      query = %Query{
        source: ["users"],
        wheres: [{:cmp, :gt, ["age"], 18}],
        select: [{:field, ["name"]}]
      }

      assert {:ok, cursor} = Executor.run(query, InMemory, conn)
      assert Cursor.to_list(cursor) == [%{"name" => "Alice"}]
    end

    test "an unknown source surfaces as {:error, {:no_such_source, ...}}, not a crash" do
      query = %Query{source: ["nonexistent"], select: [{:field, ["id"]}]}

      assert {:error, {:no_such_source, ["nonexistent"]}} =
               Executor.run(query, InMemory, Conn.new())
    end
  end
end
