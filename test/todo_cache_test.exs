defmodule TodoCacheTest do
  use ExUnit.Case

  test "get_server" do
    alice = Todo.Cache.get_server("alice")

    assert alice == Todo.Cache.get_server("alice")
    assert alice != Todo.Cache.get_server("bob")
  end

  test "todo operations" do
    # alice = Todo.Cache.get_server("alice")
    # Todo.Server.add(alice, Todo.Entry.new(~D[2020-01-01], "Shopping"))

    # entries = Todo.Server.all(alice)
    # assert entries == [%Todo.Entry{id: 1, date: ~D[2020-01-01], title: "Shopping"}]
  end
end
