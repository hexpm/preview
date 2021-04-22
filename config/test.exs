import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :preview, PreviewWeb.Endpoint,
  http: [port: 5005],
  server: false

config :goth, config: %{"project_id" => "preview"}

# Print only warnings and errors during test
config :logger, level: :warn

config :preview,
  package_store_impl: Preview.Package.StoreMock,
  hexpm_impl: Preview.HexpmMock,
  tmp_dir: "tmp/test"
