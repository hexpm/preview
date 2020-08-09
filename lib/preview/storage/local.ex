defmodule Preview.Storage.Local do
  require Logger

  @behaviour Preview.Storage

  def get(package, version) do
    case package_checksum(package, version) do
      {:ok, hash} ->
        filename = key(package, version, hash)
        path = Path.join([dir(), package, filename])

        if File.regular?(path) do
          {:ok, File.stream!(path, [:read_ahead])}
        else
          {:error, :not_found}
        end

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def put(package, version, stream) do
    with {:ok, hash} <- package_checksum(package, version),
         filename = key(package, version, hash),
         path = Path.join([dir(), package, filename]),
         :ok <- File.mkdir_p(Path.dirname(path)) do
      Enum.into(stream, File.stream!(path, [:write_delay]))
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to store preview. Reason: #{inspect(reason)}.")
        {:error, reason}
    end
  end

  def package_checksum(package, version) do
    with checksum <- Preview.Hex.get_checksum(package, version) do
      {:ok, :erlang.phash2({Application.get_env(:diff, :cache_version), checksum})}
    end
  end

  defp key(package, version, hash) do
    "#{package}-#{version}-#{hash}"
  end

  defp dir() do
    Application.get_env(:preview, :tmp_dir)
    |> Path.join("storage")
  end
end
