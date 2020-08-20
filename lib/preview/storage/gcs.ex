defmodule Preview.Storage.GCS do
  require Logger

  @behaviour Preview.Storage

  @gs_xml_url "https://storage.googleapis.com"
  @oauth_scope "https://www.googleapis.com/auth/devstorage.read_write"

  def get(package, version) do
    get_file(package, version, "files_in_package.ex")
  end

  def get_file(package, version, file) do
    with {:ok, hash} <- package_checksum(package, version),
         url = Path.join(url(key(package, version, hash)), file),
         {:ok, 200, _headers, stream} <-
           Preview.HTTP.retry("gs", fn -> Preview.HTTP.get_stream(url, headers()) end) do
      {:ok, stream}
    else
      {:ok, 404, _headers, _body} ->
        {:error, :not_found}

      {:ok, status, _headers, _body} ->
        Logger.error("Failed to get preview from storage. Status #{status}")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get preview from storage. Reason #{inspect(reason)}")
        {:error, :not_found}
    end
  end

  def put(package, version, stream) do
    with {:ok, hash} <- package_checksum(package, version),
         url = url(key(package, version, hash)) do
      files_in_package =
        Enum.reduce(stream, [], fn {name, contents}, acc ->
          path = Path.join([url, name])
          Preview.HTTP.retry("gs", fn -> Preview.HTTP.put_stream(path, headers(), contents) end)
          acc ++ [name]
        end)

      Preview.HTTP.retry("gs", fn ->
        Preview.HTTP.put_stream(
          Path.join([url, "files_in_package.ex"]),
          headers(),
          inspect(files_in_package, limit: :infinity)
        )
      end)

      :ok
    else
      {:ok, status, _headers, _body} ->
        Logger.error("Failed to put diff to storage. Status #{status}")
        {:error, :not_found}

      error ->
        Logger.error("Failed to put diff to storage. Reason #{inspect(error)}")
        error
    end
  end

  def package_checksum(package, version) do
    Preview.Hex.get_checksum(package, version)
  end

  defp headers() do
    {:ok, token} = Goth.Token.for_scope(@oauth_scope)
    [{"authorization", "#{token.type} #{token.token}"}]
  end

  defp key(package, version, hash) do
    "preview/#{package}-#{version}-#{hash}"
  end

  defp url(key) do
    "#{@gs_xml_url}/#{bucket()}/#{key}"
  end

  defp bucket() do
    Application.get_env(:preview, :bucket)
  end
end
