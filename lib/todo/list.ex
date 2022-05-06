defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}

  alias Todo.Entry

  # create empty map
  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %Todo.List{},
      &add(&2, &1)
    )
  end

  # add entry
  def add(todo_list, %Entry{} = entry) do
    auto_id = todo_list.auto_id
    entry = %Entry{entry | id: auto_id}
    entries = Map.put(todo_list.entries, auto_id, entry)

    %Todo.List{todo_list | auto_id: auto_id + 1, entries: entries}
  end

  # all entries
  def all(todo_list) do
    todo_list.entries
    |> Enum.map(fn {_, entry} -> entry end)
  end

  # entries by date
  def filter(todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def update(todo_list, %Entry{id: id} = entry) do
    case Map.fetch(todo_list.entries, id) do
      :error ->
        todo_list

      {:ok, _} ->
        new_entries = Map.put(todo_list.entries, id, entry)
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  def delete(todo_list, id) do
    new_entries =
      todo_list.entries
      |> Enum.filter(fn {i, _} -> i !== id end)

    %Todo.List{todo_list | entries: new_entries}
  end

  def csv_import(filename) do
    entries =
      File.stream!(filename)
      |> Stream.map(&String.replace(&1, "\n", ""))
      |> Enum.map(&csv_parse(&1))

    Todo.List.new(entries)
  end

  defp csv_parse(line) do
    [date_str, title] = String.split(line, ",")
    [year, month, day] = String.split(date_str, "/")
    year = String.to_integer(year)
    month = String.to_integer(month)
    day = String.to_integer(day)
    Entry.new(Date.new!(year, month, day), title)
  end
end

defimpl String.Chars, for: Todo.List do
  @moduledoc """
  Implement Chars protocol so we can call IO.puts(list)
  """

  def to_string(list) do
    inspect(list)
  end
end

defimpl Collectable, for: Todo.List do
  @moduledoc """
  Implement Collectable protocol so we can do:
  for entry <- entries, into: Todo.List.new(), do: entry
  """

  def into(original) do
    {original, &into_callback/2}
  end

  def into_callback(todo_list, {:cont, entry}) do
    Todo.List.add(todo_list, entry)
  end

  def into_callback(todo_list, :done), do: todo_list
  def into_callback(_, :halt), do: :ok
end
