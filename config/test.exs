import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :preview, PreviewWeb.Endpoint,
  http: [port: 5005],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

config :preview,
  package_store_impl: Preview.Package.StoreMock,
  hex_impl: Preview.HexMock,
  tmp_dir: "tmp/test"
