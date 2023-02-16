import Config

config :preview,
  queue_id: "dummy",
  queue_producer: Broadway.DummyProducer,
  queue_concurrency: 1,
  package_store_impl: Preview.Package.DefaultStore,
  package_updater_impl: Preview.Package.Updater,
  hex_impl: Preview.Hex.HTTP,
  repo_url: "https://repo.hex.pm"

config :preview, :repo_bucket,
  implementation: Preview.Storage.Local,
  name: "repo-bucket"

config :preview, :preview_bucket,
  implementation: Preview.Storage.Local,
  name: "preview-bucket"

# Configures the endpoint
config :preview, PreviewWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GhQNRpJEoVuQ3wOfIKRgVn/hRDKKKUQIPjJXAXDwe2gqYxk8UOsgNOghTtr94S3E",
  render_errors: [
    view: PreviewWeb.ErrorView,
    accepts: ~w(html json),
    layout: {PreviewWeb.LayoutView, :root}
  ],
  pubsub_server: Preview.PubSub,
  live_view: [signing_salt: "oPF55p/T"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :rollbax, enabled: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
