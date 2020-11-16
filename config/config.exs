# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :preview,
  queue_id: "dummy",
  queue_producer: Broadway.DummyProducer,
  package_store_impl: Preview.Package.DefaultStore

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
  render_errors: [view: PreviewWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Preview.PubSub,
  live_view: [signing_salt: "oPF55p/T"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
