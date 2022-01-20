import Config

config :logger, level: :warn
config :logger, :console, format: "[$level] $message\n"

config :phoenix, :json_library, Jason
config :phoenix, :stacktrace_depth, 20
