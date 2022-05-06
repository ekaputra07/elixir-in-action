defmodule Todo.Cache do
  alias Todo.Server

  # -- process functions
  def start_link do
    IO.puts("Starting todo-servers dynamic supervisor")

    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  def child_spec(_) do
    # since this is a plain module that we convert into a process (DymamicSupervisor)
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  # -- client_interfaces
  def get_server(name) do
    existing_child(name) || new_child(name)
  end

  defp existing_child(name) do
    Server.whereis(name)
  end

  defp new_child(name) do
    case DynamicSupervisor.start_child(
           __MODULE__,
           {Server, name}
         ) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
