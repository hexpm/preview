defmodule Preview.Package.Supervisor do
  use Supervisor

  alias Preview.Package.{Store, Updater}

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], [])
  end

  @impl true
  @spec init(any) :: {:ok, {%{intensity: any, period: any, strategy: any}, [any]}}
  def init(_opts) do
    children = [
      {Store, []},
      {Updater, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
