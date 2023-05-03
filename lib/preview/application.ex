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
      goth_spec(),
      Preview.Queue,
      PreviewWeb.Endpoint,
      package_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Preview.Supervisor]
    Supervisor.start_link(children, opts)
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

  defp finch_pools() do
    %{default: [size: 50, count: 1, conn_max_idle_time: 10_000]}
  end

  if Mix.env() == :prod do
    defp goth_spec() do
      credentials =
        "PREVIEW_GCP_CREDENTIALS"
        |> System.fetch_env!()
        |> Jason.decode!()

      options = [scopes: ["https://www.googleapis.com/auth/devstorage.read_write"]]
      {Goth, name: Preview.Goth, source: {:service_account, credentials, options}}
    end
  else
    defp goth_spec() do
      Supervisor.child_spec({Task, fn -> :ok end}, id: :goth)
    end
  end

  if Mix.env() != :test do
    defp package_spec() do
      Preview.Package.Supervisor
    end
  else
    defp package_spec() do
      Supervisor.child_spec({Task, fn -> :ok end}, id: :package)
    end
  end
end
