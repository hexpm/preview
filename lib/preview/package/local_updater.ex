defmodule Preview.Package.LocalUpdater do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    Logger.debug("Skipping version updater")

    Preview.Package.Store.fill([
      {"phoenix_live_view", ["1.0.0"]},
      {"decimal", ["2.0.0"]},
      {"ecto", ["0.2.0"]},
      {"telemetry", ["0.4.2"]}
    ])

    {:ok, []}
  end
end
