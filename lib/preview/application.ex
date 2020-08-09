defmodule Preview.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      PreviewWeb.Telemetry,
      {Phoenix.PubSub, name: Preview.PubSub},
      {Task.Supervisor, name: Preview.Tasks},
      PreviewWeb.Endpoint,
      {Finch, name: PreviewFinch},
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
end
