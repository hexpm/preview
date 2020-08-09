defmodule Preview.Hex do
  @config %{
    :hex_core.default_config()
    | http_adapter: Preview.Hex.Adapter,
      http_user_agent_fragment: "hexpm_preview"
  }

  require Logger

  def get_versions() do
    with {:ok, {200, _, results}} <- :hex_repo.get_versions(@config) do
      {:ok, results}
    else
      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get package versions. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def get_tarball(package, version) do
    with {:ok, {200, _, tarball}} <- :hex_repo.get_tarball(@config, package, version) do
      {:ok, tarball}
    else
      {:ok, {403, _, _}} ->
        {:error, :not_found}

      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get tarball for package: #{package}. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def unpack_tarball(tarball, :memory) do
    with {:ok, contents} <- :hex_tarball.unpack(tarball, :memory) do
      {:ok, contents}
    end
  end

  def unpack_tarball(tarball, path) when is_binary(path) do
    path = to_charlist(path)

    with {:ok, _} <- :hex_tarball.unpack(tarball, path) do
      :ok
    end
  end

  def get_checksum(package, version) do
    with {:ok, {200, _, releases}} <- :hex_repo.get_package(@config, package) do
      checksum =
        for release <- releases, release.version == version do
          release.outer_checksum
        end

      {:ok, checksum}
    else
      {:ok, {status, _, _}} ->
        Logger.error("Failed to get checksum for package: #{package}. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get checksum for package: #{package}. Reason: #{inspect(reason)}")

        {:error, :not_found}
    end
  end

  def preview(package, version) do
    with {:ok, tarball} <- get_tarball(package, version),
         {:ok, %{contents: contents}} <- unpack_tarball(tarball, :memory) do
      {:ok, contents}
    else
      error ->
        Logger.error("Failed to create preview #{package} #{version} with: #{inspect(error)}")

        :error
    end
  end
end
