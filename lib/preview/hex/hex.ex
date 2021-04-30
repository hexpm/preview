defmodule Preview.Hex do
  @callback get_names() :: {:ok, [map()]} | {:error, term()}
  @callback get_versions() :: {:ok, [map()]} | {:error, term()}
  @callback get_checksum(String.t(), String.t()) :: {:ok, [binary()]} | {:error, term()}

  def get_names(), do: impl().get_names()

  def get_versions(), do: impl().get_versions()

  def get_checksum(package, version), do: impl().get_checksum(package, version)

  defp impl(), do: Application.get_env(:preview, :hex_impl)

  def unpack_tarball(tarball, :memory) do
    with {:ok, contents} <- :hex_tarball.unpack(tarball, :memory) do
      {:ok, contents}
    end
  end

  def unpack_tarball(tarball, path) when is_binary(path) do
    with {:ok, _} <- :hex_tarball.unpack(tarball, String.to_charlist(path)) do
      :ok
    end
  end
end
