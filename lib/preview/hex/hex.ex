defmodule Preview.Hex do
  @callback get_names() :: {:ok, [map()]} | {:error, term()}
  @callback get_versions() :: {:ok, [map()]} | {:error, term()}
  @callback get_package(String.t()) :: {:ok, [map()]} | {:error, term()}
  @callback get_checksum(String.t(), String.t()) :: {:ok, [binary()]} | {:error, term()}

  def get_names(), do: impl().get_names()

  def get_versions(), do: impl().get_versions()

  def get_package(package), do: impl().get_package(package)

  def get_checksum(package, version), do: impl().get_checksum(package, version)

  defp impl(), do: Application.get_env(:preview, :hex_impl)

  def unpack_tarball(tarball_path, output_path)
      when is_binary(tarball_path) and is_binary(output_path) do
    with {:ok, _} <-
           :hex_tarball.unpack({:file, to_charlist(tarball_path)}, to_charlist(output_path)) do
      ensure_readable(output_path)
      :ok
    end
  end

  defp ensure_readable(dir) do
    dir
    |> Path.join("**")
    |> Path.wildcard(match_dot: true)
    |> Enum.each(fn path ->
      case File.stat(path) do
        {:ok, %{type: :directory, access: access}} when access in [:none, :write] ->
          File.chmod(path, 0o755)

        {:ok, %{type: :regular, access: access}} when access in [:none, :write] ->
          File.chmod(path, 0o644)

        _ ->
          :ok
      end
    end)
  end
end
