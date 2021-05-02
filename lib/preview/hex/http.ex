defmodule Preview.Hex.HTTP do
  @behaviour Preview.Hex

  require Logger

  @impl true
  def get_names() do
    case :hex_repo.get_names(config()) do
      {:ok, {200, _, results}} ->
        {:ok, results}

      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package names. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get package names. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  @impl true
  def get_versions() do
    case :hex_repo.get_versions(config()) do
      {:ok, {200, _, results}} ->
        {:ok, results}

      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get package versions. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  @impl true
  def get_package(package) do
    case :hex_repo.get_package(config(), package) do
      {:ok, {200, _, releases}} ->
        {:ok, releases}

      {:ok, {status, _, _}} ->
        Logger.error("Failed to get checksum for package: #{package}. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get checksum for package: #{package}. Reason: #{inspect(reason)}")
        {:error, :not_found}
    end
  end

  @impl true
  def get_checksum(package, version) do
    with {:ok, releases} <- get_package(package) do
      checksum =
        for release <- releases, release.version == version do
          release.outer_checksum
        end

      {:ok, checksum}
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
      %{config | repo_verify: false}
    end
  end
end
