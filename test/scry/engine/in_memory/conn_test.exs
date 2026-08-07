defmodule Scry.Engine.InMemory.ConnTest do
  @moduledoc """
  `Scry.Engine.InMemory.Conn` -- `new/1`'s own empty-by-default and
  supplied-data cases, and `put/3` both creating a new source and
  appending to an existing one.
  """

  use ExUnit.Case, async: true

  alias Scry.Engine.InMemory.Conn

  test "new/1 is empty by default" do
    assert Conn.new().data == %{}
  end

  test "new/1 starts from whatever data is supplied" do
    assert Conn.new(%{["x"] => [%{"a" => 1}]}).data == %{["x"] => [%{"a" => 1}]}
  end

  test "put/3 creates a source that didn't exist yet" do
    conn = Conn.new() |> Conn.put(["users"], [%{"name" => "Alice"}])

    assert conn.data == %{["users"] => [%{"name" => "Alice"}]}
  end

  test "put/3 appends to a source that already has rows" do
    conn =
      Conn.new(%{["users"] => [%{"name" => "Alice"}]})
      |> Conn.put(["users"], [%{"name" => "Bob"}])

    assert conn.data == %{["users"] => [%{"name" => "Alice"}, %{"name" => "Bob"}]}
  end
end
