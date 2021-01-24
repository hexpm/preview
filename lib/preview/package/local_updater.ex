defmodule Preview.Package.LocalUpdater do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    Logger.debug("Skipping version updater")
    {:ok, []}
  end
end
