defmodule Todo.ProcessRegistry do
  @moduledoc """
  UNUSED. replaced by :global process registry.
  """
  def start_link do
    IO.puts("Staring process registry")
    # start process registry named this module where keys must be unique
    Registry.start_link(name: __MODULE__, keys: :unique)
  end

  def via_tuple(key) do
    # helper function to create valid via-tuple for this registry
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    # since this is a plain module that we convert into a process (Registry)
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
end
