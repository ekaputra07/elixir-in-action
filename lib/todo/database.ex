defmodule Todo.Database do
  @moduledoc """
  This module act as both interface for database operations as well as Database Worker supervisor
  """
  alias Todo.DatabaseWorker

  @num_workers Application.fetch_env!(:todo, :db_num_workers)

  def child_spec(_) do
    db_folder = Application.fetch_env!(:todo, :db_folder)

    IO.puts("Starting DB poolboy #{db_folder}")

    File.mkdir_p!(db_folder)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: DatabaseWorker,
        size: @num_workers
      ],
      [db_folder]
    )
  end

  # client interface
  def put(key, data) do
    [_results, bad_nodes] =
      :rpc.multicall(
        __MODULE__,
        :put_local,
        [key, data],
        :timer.seconds(5)
      )

    Enum.each(bad_nodes, &IO.puts("database put failed on node #{&1}"))
  end

  def put_local(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        DatabaseWorker.put(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        DatabaseWorker.get(worker_pid, key)
      end
    )
  end
end
