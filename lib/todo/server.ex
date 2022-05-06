defmodule Todo.Server do
  # temporary worker: if crash, wont be restarted by supervisor
  use GenServer, restart: :temporary

  alias Todo.List
  alias Todo.Entry
  alias Todo.Database

  @expiry_idle_timeout :timer.seconds(60)

  # process functions
  def start_link(todo_name) do
    IO.puts("Starting todo-server #{todo_name}")
    GenServer.start_link(__MODULE__, todo_name, name: global_name(todo_name))
  end

  defp global_name(name) do
    {:global, {__MODULE__, name}}
  end

  def whereis(name) do
    case :global.whereis_name({__MODULE__, name}) do
      :undefined -> nil
      pid -> pid
    end
  end

  # client interfaces
  def stop(pid) do
    GenServer.stop(pid)
  end

  def bad(pid) do
    cast(pid, :bad)
    call(pid, :bad)
  end

  def add(pid, %Entry{} = entry) do
    cast(pid, {:add, entry})
  end

  def update(pid, %Entry{} = entry) do
    cast(pid, {:update, entry})
  end

  def delete(pid, entry_id) do
    cast(pid, {:delete, entry_id})
  end

  def all(pid, date \\ nil) do
    case date do
      nil -> call(pid, :all)
      date -> call(pid, {:filter, date})
    end
  end

  def import(pid, file_path) do
    cast(pid, {:import, file_path})
  end

  # helpers
  defp call(pid, request) do
    GenServer.call(pid, request)
  end

  defp cast(pid, request) do
    GenServer.cast(pid, request)
  end

  # callbacks
  @impl GenServer
  def init(todo_name) do
    IO.puts("Todo server #{todo_name} started.")
    # :timer.send_interval(5000, :healthcheck)

    # we don;t want to do long blocking process here
    # so we send message :real_init to ourself, handle by handle_info(:real_init, state)
    # where we do blocking operation
    send(self(), :real_init)

    # {name, todo} <-- named_todo
    {:ok, {todo_name, nil}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_info(:real_init, {name, _}) do
    IO.puts("Real init for Todo.Server: #{inspect(name)}")
    # on server start we check DB:
    # - if data exist then return existing data
    # - otherwise return initial todo
    {:noreply, {name, Database.get(name) || List.new()}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_info(:timeout, {name, todo}) do
    IO.puts("Stopping server #{name} (inactive for #{@expiry_idle_timeout}ms)")
    {:stop, :normal, {name, todo}}
  end

  @impl GenServer
  def handle_info(request, named_todo) do
    IO.puts("Handling custom request: #{inspect(request)}")
    {:noreply, named_todo, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:add, entry}, {name, todo}) do
    new_todo = List.add(todo, entry)
    Database.put(name, new_todo)
    {:noreply, {name, new_todo}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:update, entry}, {name, todo}) do
    new_todo = List.update(todo, entry)
    Database.put(name, new_todo)
    {:noreply, {name, new_todo}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:delete, entry_id}, {name, todo}) do
    new_todo = List.delete(todo, entry_id)
    Database.put(name, new_todo)
    {:noreply, {name, new_todo}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast({:import, file_path}, {name, todo}) do
    # this list entries already have id
    imported_entries =
      List.csv_import(file_path).entries
      |> Enum.map(fn {_, entry} -> entry end)

    # add imported list into current list
    new_todo = Enum.reduce(imported_entries, todo, &List.add(&2, &1))
    Database.put(name, new_todo)
    {:noreply, {name, new_todo}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_cast(unknown, named_todo) do
    IO.puts("Unknown cast: #{inspect(unknown)}")
    {:noreply, named_todo, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call(:all, _caller, {name, todo}) do
    entries = List.all(todo)
    {:reply, entries, {name, todo}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call({:filter, date}, _caller, {name, todo}) do
    entries = List.filter(todo, date)
    {:reply, entries, {name, todo}, @expiry_idle_timeout}
  end

  @impl GenServer
  def handle_call(unknown, _caller, named_todo) do
    IO.puts("Unknown call: #{inspect(unknown)}")
    {:reply, :unknown, named_todo, @expiry_idle_timeout}
  end
end
