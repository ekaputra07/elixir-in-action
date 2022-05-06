defmodule Todo.System do
  def start_link do
    Supervisor.start_link(
      [
        # ordering matter
        Todo.Metrics,
        # Todo.ProcessRegistry,
        # db interface & db workers supervisor
        Todo.Database,
        # server interface & servers supervisore
        Todo.Cache,
        Todo.Web
      ],
      strategy: :one_for_one
    )
  end
end
