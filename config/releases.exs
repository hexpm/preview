import Config

config :preview, preview_bucket: System.fetch_env!("PREVIEW_BUCKET")

config :goth, json: System.fetch_env!("HEXDOCS_GCP_CREDENTIALS")

config :rollbax,
  access_token: System.fetch_env!("PREVIEW_ROLLBAR_ACCESS_TOKEN")
