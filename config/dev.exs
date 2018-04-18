use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :ex_subtil_backend, ExSubtilBackendWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--watch",
      "--watch-poll",
      "--stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :ex_subtil_backend, ExSubtilBackendWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/ex_subtil_backend_web/views/.*(ex)$},
      ~r{lib/ex_subtil_backend_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
config :logger, level: :debug
# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :ex_subtil_backend, ExSubtilBackend.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ex_subtil_backend_dev",
  hostname: "localhost",
  pool_size: 10

config :ex_subtil_backend,
  hostname: "http://localhost:4000",
  workdir: "/tmp/ftp_francetv",
  akamai_video_prefix: "/421959/prod/innovation/testing",
  docker_hosts: [
    [hostname: "http://localhost", port: 2357]
  ],
  rdf_converter: [
    hostname: "localhost",
    port: 1501
  ],
  appdir: "/opt/app",
  root_email: "admin@media-io.com",
  root_password: "admin123"

config :amqp,
  hostname: "localhost",
  username: "guest",
  password: "guest"

# Finally import the config/prod.secret.exs
# with the private section for passwords
import_config "dev.secret.exs"
