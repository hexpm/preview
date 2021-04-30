defmodule Preview.Hexpm.HTTP do
  @behaviour Preview.Hexpm

  @impl true
  def get_package(package) do
    key = Application.fetch_env!(:preview, :hexpm_secret)

    result =
      Preview.HTTP.retry("hexpm", fn ->
        Preview.HTTP.get(url("/api/packages/#{package}"), headers(key))
      end)

    case result do
      {:ok, 200, _headers, body} -> Jason.decode!(body)
      {:ok, 404, _headers, _body} -> nil
    end
  end

  defp url(path) do
    Application.fetch_env!(:preview, :hexpm_url) <> path
  end

  defp headers(key) do
    [
      {"accept", "application/json"},
      {"authorization", key}
    ]
  end
end
