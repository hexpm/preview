import Config

if config_env() == :prod do
  config :preview,
    host: System.fetch_env!("PREVIEW_HOST"),
    repo_url: System.fetch_env!("PREVIEW_REPO_URL"),
    repo_public_key: System.fetch_env!("PREVIEW_REPO_PUBLIC_KEY"),
    queue_id: System.fetch_env!("PREVIEW_QUEUE_ID"),
    queue_concurrency: String.to_integer(System.fetch_env!("PREVIEW_QUEUE_CONCURRENCY")),
    fastly_key: System.fetch_env!("PREVIEW_FASTLY_KEY"),
    fastly_repo: System.fetch_env!("PREVIEW_FASTLY_REPO"),
    plausible_url: "https://stats.hex.pm/js/plausible.js"

  config :preview, :repo_bucket,
    implementation: Preview.Storage.S3,
    name: System.fetch_env!("PREVIEW_REPO_BUCKET")

  config :preview, :preview_bucket,
    implementation: Preview.Storage.GCS,
    name: System.fetch_env!("PREVIEW_BUCKET")

  config :preview, PreviewWeb.Endpoint,
    http: [port: String.to_integer(System.fetch_env!("PREVIEW_PORT"))],
    url: [host: System.fetch_env!("PREVIEW_HOST")],
    secret_key_base: System.fetch_env!("PREVIEW_SECRET_KEY_BASE")

  config :ex_aws,
    access_key_id: System.fetch_env!("PREVIEW_AWS_ACCESS_KEY_ID"),
    secret_access_key: System.fetch_env!("PREVIEW_AWS_ACCESS_KEY_SECRET")

  config :sentry,
    dsn: System.fetch_env!("PREVIEW_SENTRY_DSN"),
    environment_name: System.fetch_env!("PREVIEW_ENV")

  beam_port = String.to_integer(System.fetch_env!("BEAM_PORT"))

  config :kernel,
    inet_dist_listen_min: beam_port,
    inet_dist_listen_max: beam_port
end
