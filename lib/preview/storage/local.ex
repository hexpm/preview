defmodule Preview.Storage.Local do
  require Logger

  @behaviour Preview.Storage

  def get(package, version) do
    with {:ok, hash} <- package_checksum(package, version),
         filename <- key(package, version, hash),
         path <- Path.join([dir(), package, filename]),
         true <- File.dir?(path) do
      {:ok, files_in_package(package, filename)}
    else
      _error -> {:error, :not_found}
    end
  end

  def get_file(package, version, file) do
    with {:ok, hash} <- package_checksum(package, version),
         filename <- key(package, version, hash),
         path <- Path.join([dir(), package, filename, file]),
         true <- File.regular?(path) do
      {:ok, File.read!(path)}
    else
      _error -> {:error, :not_found}
    end
  end

  def put(package, version, stream) do
    with {:ok, hash} <- package_checksum(package, version),
         filename = key(package, version, hash) do
      files_in_package =
        Enum.reduce(stream, [], fn {name, contents}, acc ->
          path = Path.join([dir(), package, filename, name])
          File.mkdir_p(Path.dirname(path))
          File.write(path, contents)
          acc ++ [name]
        end)

      File.write(
        Path.join([dir(), package, filename, "files_in_package.ex"]),
        inspect(files_in_package, limit: :infinity)
      )

      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to store preview. Reason: #{inspect(reason)}.")
        {:error, reason}
    end
  end

  def package_checksum(package, version) do
    with checksum <- Preview.Hex.get_checksum(package, version) do
      {:ok, :erlang.phash2({Application.get_env(:preview, :cache_version), checksum})}
    end
  end

  defp key(package, version, hash) do
    "#{package}-#{version}-#{hash}"
  end

  defp dir() do
    Application.get_env(:preview, :tmp_dir)
    |> Path.join("storage")
  end

  defp files_in_package(pkg, key) do
    {ls, _bindings} = [dir(), pkg, key, "files_in_package.ex"] |> Path.join() |> Code.eval_file()
    ls
  end
end
