defmodule Todo.Web do
  use Plug.Router
  plug(:match)
  plug(:dispatch)

  def child_spec(_) do
    Plug.Adapters.Cowboy.child_spec(
      scheme: :http,
      options: [port: Application.fetch_env!(:todo, :http_port)],
      plug: __MODULE__
    )
  end

  defp http_response(conn, code \\ 200, body \\ "OK") do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(code, body)
  end

  get "/add" do
    conn = Plug.Conn.fetch_query_params(conn)
    todo = Map.fetch!(conn.params, "todo")
    title = Map.fetch!(conn.params, "title")
    date = Date.from_iso8601!(Map.fetch!(conn.params, "date"))

    todo
    |> Todo.Cache.get_server()
    |> Todo.Server.add(Todo.Entry.new(date, title))

    http_response(conn)
  end

  get "/" do
    conn = Plug.Conn.fetch_query_params(conn)
    todo = Map.fetch!(conn.params, "todo")

    entries =
      todo
      |> Todo.Cache.get_server()
      |> Todo.Server.all()

    formatted_entries =
      entries
      |> Enum.map(&"#{&1.date} #{&1.title}")
      |> Enum.join("\n")

    http_response(conn, 200, formatted_entries)
  end
end
