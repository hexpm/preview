defmodule Preview.Package.Supervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], [])
  end

  @impl true
  def init(_opts) do
    children = [{Preview.Package.Store, []}, {updater_module(), []}]
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp updater_module, do: Application.get_env(:preview, :package_updater_impl)
end
