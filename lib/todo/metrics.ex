defmodule Todo.Metrics do
  use Task

  # process
  def start_link(_) do
    IO.puts("Starting metrics")
    Task.start_link(&loop/0)
  end

  # task logic
  defp loop do
    Process.sleep(:timer.seconds(10))
    collect_metrics()
    # IO.inspect(collect_metrics())

    loop()
  end

  defp collect_metrics do
    [
      memory_usage: :erlang.memory(:total),
      process_count: :erlang.system_info(:process_count),
      db_folder: Application.fetch_env!(:todo, :db_folder),
      db_num_workers: Application.fetch_env!(:todo, :db_num_workers)
    ]
  end
end
