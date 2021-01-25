defmodule Preview.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    setup_tmp_dir()

    children = [
      PreviewWeb.Telemetry,
      {Phoenix.PubSub, name: Preview.PubSub},
      {Task.Supervisor, name: Preview.Tasks},
      {Finch, name: Preview.Finch, pools: finch_pools()},
      Preview.Queue,
      PreviewWeb.Endpoint,
      Preview.Package.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Preview.Supervisor]
    sup = Supervisor.start_link(children, opts)

    setup_local_ets()

    sup
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PreviewWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp setup_tmp_dir() do
    if dir = Application.get_env(:preview, :tmp_dir) do
      File.mkdir_p!(dir)
      Application.put_env(:preview, :tmp_dir, Path.expand(dir))
    end
  end

  if Application.get_env(:preview, :package_updater_impl) == Preview.Package.LocalUpdater do
    defp setup_local_ets do
      Preview.Package.Store.fill([{"decimal", ["2.0.0"]}, {"ecto", ["0.2.0"]}])
    end
  else
    defp setup_local_ets, do: nil
  end

  defp finch_pools() do
    %{default: [size: 10, count: 1, max_idle_time: 10_000]}
  end
end
