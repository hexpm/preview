defmodule Preview.Hex do
  require Logger

  def get_versions() do
    with {:ok, {200, _, results}} <- :hex_repo.get_versions(config()) do
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
    with {:ok, {200, _, releases}} <- :hex_repo.get_package(config(), package) do
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

  defp config() do
    config = %{
      :hex_core.default_config()
      | http_adapter: {Preview.Hex.Adapter, %{}},
        http_user_agent_fragment: "hexpm_preview",
        repo_url: Application.fetch_env!(:preview, :repo_url)
    }

    if repo_public_key = Application.get_env(:preview, :repo_public_key) do
      %{config | repo_public_key: repo_public_key}
    else
      config
    end
  end
end
