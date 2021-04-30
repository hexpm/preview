defmodule Preview.Hexpm do
  @callback get_package(package :: String.t()) :: map() | nil

  def get_package(package), do: impl().get_package(package)

  defp impl(), do: Application.get_env(:preview, :hexpm_impl)
end
