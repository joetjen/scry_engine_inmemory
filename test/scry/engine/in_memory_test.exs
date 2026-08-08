defmodule Scry.Engine.InMemoryTest do
  @moduledoc """
  `Scry.Engine.InMemory` -- confirms `execute/3` behaves exactly like
  the in-memory engines this package is extracted from (a known source
  answers the whole query correctly, an unknown one is a clear
  `{:error, {:query_error, ...}}`, never a raise), composes end to end
  with a real `Scry.Core.Executor.run/4` call, and correctly delegates
  `WITH`/nested-`SELECT` documents to `Scry.Core.QueryOps.run_document/4`
  rather than only ever handling a single flat query.
  """

  use ExUnit.Case, async: true

  alias Scry.Core.{Cursor, Executor, Query}
  alias Scry.Engine.InMemory
  alias Scry.Engine.InMemory.Conn

  describe "execute/3" do
    test "answers a flat query for a known source" do
      conn = Conn.new(%{["users"] => [%{"name" => "Alice", "age" => 30}]})
      query = %Query{source: ["users"], select: [{:field, ["name"]}]}

      assert {:ok, rows} = InMemory.execute(conn, query, %{})
      assert Enum.to_list(rows) == [%{"name" => "Alice"}]
    end

    test "returns a clear, tagged error for an unknown source, never raises" do
      conn = Conn.new(%{["users"] => []})
      query = %Query{source: ["orders"], select: []}

      assert InMemory.execute(conn, query, %{}) ==
               {:error, {:query_error, {:no_such_source, ["orders"]}}}
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

    test "an unknown source surfaces as {:error, {:query_error, {:no_such_source, ...}}}, not a crash" do
      query = %Query{source: ["nonexistent"], select: [{:field, ["id"]}]}

      assert {:error, {:query_error, {:no_such_source, ["nonexistent"]}}} =
               Executor.run(query, InMemory, Conn.new())
    end

    test "a WITH binding is resolved via QueryOps.run_document/4, not just a real source" do
      conn = Conn.new(%{["orders"] => [%{"customer_id" => 1, "total" => 50}]})

      query = %Query{
        source: ["recent"],
        select: [{:field, ["total"]}],
        with_bindings: %{
          "recent" => %Query{source: ["orders"], select: [{:field, ["total"]}]}
        }
      }

      assert {:ok, cursor} = Executor.run(query, InMemory, conn)
      assert Cursor.to_list(cursor) == [%{"total" => 50}]
    end

    test "a correlated nested SELECT is resolved via QueryOps.run_document/4" do
      conn =
        Conn.new(%{
          ["customers"] => [%{"id" => 1, "name" => "Alice"}],
          ["orders"] => [
            %{"customer_id" => 1, "id" => 100},
            %{"customer_id" => 2, "id" => 200}
          ]
        })

      query = %Query{
        source: ["customers"],
        select: [
          {:field, ["name"]},
          %Query{
            source: ["orders"],
            wheres: [{:cmp, :eq, ["customer_id"], {:field, ["customers", "id"]}}],
            select: [{:field, ["id"]}]
          }
        ]
      }

      assert {:ok, cursor} = Executor.run(query, InMemory, conn)
      assert Cursor.to_list(cursor) == [%{"name" => "Alice", "orders" => [%{"id" => 100}]}]
    end
  end
end
