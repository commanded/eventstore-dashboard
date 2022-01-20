# iex -S mix run dev.exs
Logger.configure(level: :debug)

# Configures the endpoint
Application.put_env(:phoenix_live_dashboard, DemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "CbOd1GvP+3OEa8DRCtLyBQIQAyaGuUEwJNrZvZj4n8wFqFvqL3gNtMnHg+UpuBgx",
  live_view: [signing_salt: "3yRfxqXO9BqYXEGqZ4cPjk9KRDvzng6L"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub
)

Application.put_env(:phoenix_live_dashboard, Demo.EventStore,
  serializer: EventStore.JsonSerializer,
  username: System.get_env("EVENTSTORE_USERNAME", "postgres"),
  password: System.get_env("EVENTSTORE_PASSWORD", "postgres"),
  database: System.get_env("EVENTSTORE_DATABASE", "eventstore_dashboard"),
  hostname: System.get_env("EVENTSTORE_HOSTNAME", "localhost"),
  pool_size: 1
)

defmodule Demo.EventStore do
  use EventStore, otp_app: :phoenix_live_dashboard
end

defmodule Event do
  @derive Jason.Encoder
  defstruct [:data, version: "1"]
end

defmodule Snapshot do
  @derive Jason.Encoder
  defstruct [:data, version: "1"]
end

event_store_config = Demo.EventStore.config()

EventStore.Tasks.Create.exec(event_store_config)
EventStore.Tasks.Init.exec(event_store_config)

# To seed the event store with test data run the following from the eventstore repo:
#
#   MIX_ENV=test mix run test/manual/seed_eventstore.exs

defmodule DemoWeb.PageController do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, :index) do
    content(conn, """
    <h2>EventStore Dashboard Dev</h2>
    <a href="/dashboard" target="_blank">Open Dashboard</a>
    """)
  end

  defp content(conn, content) do
    conn
    |> put_resp_header("content-type", "text/html")
    |> send_resp(200, "<!doctype html><html><body>#{content}</body></html>")
  end
end

defmodule DemoWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)

    get("/", DemoWeb.PageController, :index)

    live_dashboard("/dashboard",
      allow_destructive_actions: true,
      additional_pages: [
        eventstores: EventStore.Dashboard
      ]
    )
  end
end

defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_live_dashboard

  socket("/live", Phoenix.LiveView.Socket)
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "1uszN0TKEQxzCSG7cRpZ6pYx3w3BHRsw"
  )

  plug(Plug.RequestId)
  plug(DemoWeb.Router)
end

Application.put_env(:phoenix, :serve_endpoints, true)

Task.start(fn ->
  children = [
    {Phoenix.PubSub, [name: Demo.PubSub, adapter: Phoenix.PubSub.PG2]},
    Demo.EventStore,
    DemoWeb.Endpoint
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

  Process.sleep(:infinity)
end)
