import Config

config :preview, preview_bucket: System.fetch_env!("PREVIEW_BUCKET")

config :ex_aws,
  access_key_id: System.fetch_env!("PREVIEW_AWS_ACCESS_KEY_ID"),
  secret_access_key: System.fetch_env!("PREVIEW_AWS_ACCESS_KEY_SECRET")

config :goth, json: System.fetch_env!("PREVIEW_GCP_CREDENTIALS")

config :rollbax,
  access_token: System.fetch_env!("PREVIEW_ROLLBAR_ACCESS_TOKEN")

config :kernel,
  inet_dist_listen_min: String.to_integer(System.fetch_env!("BEAM_PORT")),
  inet_dist_listen_max: String.to_integer(System.fetch_env!("BEAM_PORT"))
