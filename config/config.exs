import Config

config :preview,
  queue_id: "dummy",
  queue_producer: Broadway.DummyProducer,
  queue_concurrency: 2,
  package_store_impl: Preview.Package.DefaultStore,
  package_updater_impl: Preview.Package.Updater,
  hex_impl: Preview.Hex.HTTP,
  cdn_impl: Preview.CDN.Local,
  repo_url: "https://repo.hex.pm",
  gcs_put_debounce: 0

config :preview, :repo_bucket,
  implementation: Preview.Storage.Local,
  name: "repo-bucket"

config :preview, :preview_bucket,
  implementation: Preview.Storage.Local,
  name: "preview-bucket"

# Configures the endpoint
config :preview, PreviewWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  secret_key_base: "GhQNRpJEoVuQ3wOfIKRgVn/hRDKKKUQIPjJXAXDwe2gqYxk8UOsgNOghTtr94S3E",
  render_errors: [
    view: PreviewWeb.ErrorView,
    accepts: ~w(html json),
    layout: {PreviewWeb.LayoutView, :root}
  ],
  pubsub_server: Preview.PubSub,
  live_view: [signing_salt: "oPF55p/T"]

config :esbuild,
  version: "0.25.0",
  preview: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "4.1.11",
  default: [
    args: ~w(
      --input=./assets/css/app.css
      --output=./priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter, format: "$metadata[$level] $message\n"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
