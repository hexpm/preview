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
      {Finch, name: Preview.Finch},
      Preview.Queue,
      PreviewWeb.Endpoint,
      Preview.Package.Supervisor
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
end
