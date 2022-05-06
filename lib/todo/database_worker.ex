defmodule Todo.DatabaseWorker do
  use GenServer

  # supervisor interface
  def start_link(folder) do
    IO.puts("Starting DB Worker")
    GenServer.start_link(__MODULE__, folder)
  end

  # client interfaces
  def put(worker_id, key, data) do
    GenServer.call(worker_id, {:put, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(worker_id, {:get, key})
  end

  # callbacks
  @impl GenServer
  def init(folder) do
    {:ok, folder}
  end

  @impl GenServer
  def handle_call({:put, key, data}, _caller, folder) do
    result =
      key
      |> file_name(folder)
      |> File.write(:erlang.term_to_binary(data))

    IO.puts("DB put on worker")
    {:reply, result, folder}
  end

  @impl GenServer
  def handle_call({:get, key}, _caller, folder) do
    data =
      case File.read(file_name(key, folder)) do
        {:ok, content} -> :erlang.binary_to_term(content)
        _ -> nil
      end

    IO.puts("DB get on worker")
    {:reply, data, folder}
  end

  defp file_name(key, folder) do
    Path.join(folder, to_string(key))
  end
end
