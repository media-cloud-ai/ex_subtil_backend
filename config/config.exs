# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :ex_backend,
  ecto_repos: [
    ExBackend.Repo,
    StepFlow.Repo
  ]

# Configures the endpoint
config :ex_backend, ExBackendWeb.Endpoint,
  url: [host: "media-cloud.ai"],
  server: true,
  secret_key_base: "VQyOE7QLAMr0qyhIR+4/NtEK9G8DU+mdESssX4ZO0j05mchaW1VzebD2dZ+r9xCS",
  render_errors: [view: ExBackendWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: ExBackend.PubSub

# Mailer configuration
config :ex_backend, ExBackend.Mailer, adapter: Bamboo.LocalAdapter

config :step_flow, StepFlow,
  exposed_domain_name: {:system, "EXPOSED_DOMAIN_NAME"},
  slack_api_token: {:system, "SLACK_API_TOKEN"},
  slack_api_channel: {:system, "SLACK_API_CHANNEL"},
  teams_channel_url: {:system, "TEAMS_CHANNEL_URL"},
  work_dir: "/data",
  authorize: [
    module: ExBackendWeb.Authorize,
    get_jobs: [:user_check],
    get_workflows: [:user_check],
    post_workflows: [:user_check],
    post_launch_workflow: [:user_check],
    put_workflows: [:user_check],
    delete_workflows: [:user_check],
    post_workflows_events: [:user_check],
    get_definitions: [:user_check],
    get_definitions_identifiers: [:user_check],
    post_definitions: [:user_check],
    post_worker_definitions: [:user_check],
    get_worker_definitions: [:user_check],
    get_workflows_statistics: [:user_check],
    get_live_workers: [:user_check],
    get_metrics: [],
    get_live_workers: [:user_check]
  ],
  endpoint: ExBackendWeb.Endpoint

config :ex_backend, :pow,
  user: ExBackend.Accounts.User,
  repo: ExBackend.Repo

# Configures Elixir's Logger
config :logger,
  backends: [Logger.Backends.Console],
  format: "[$level] $message\n"

config :mime, :types, %{
  "application/json" => ["json"],
  "application/wasm" => ["wasm"],
  "text/vtt" => ["webvtt"]
}

config :blue_bird,
  docs_path: "priv/static/docs",
  theme: "triple",
  router: ExBackendWeb.Router

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
