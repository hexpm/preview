defmodule Preview.Hexpm do
  @callback get_package(package :: String.t()) :: map() | nil

  @callback preview_sitemap() :: binary()

  def get_package(package), do: impl().get_package(package)

  def preview_sitemap(), do: impl().preview_sitemap()

  defp impl(), do: Application.get_env(:preview, :hexpm_impl)
end
