defmodule Todo.Entry do
  @enforce_keys [:date, :title]
  defstruct [:id, :date, :title]

  def new(date, title) do
    %Todo.Entry{date: date, title: title}
  end
end

defimpl String.Chars, for: Todo.Entry do
  @moduledoc """
  Implement Chars protocol so we can call IO.puts(entry)
  """

  def to_string(entry) do
    inspect(entry)
  end
end
