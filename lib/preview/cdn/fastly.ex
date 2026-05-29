defmodule Preview.CDN.Fastly do
  @behaviour Preview.CDN
  @fastly_url "https://api.fastly.com/"
  @fastly_purge_wait 4000

  def purge_key(service, keys) do
    keys = keys |> List.wrap() |> Enum.uniq()
    body = %{"surrogate_keys" => keys}
    service_id = Application.get_env(:preview, service)
    sleep_time = div(Application.get_env(:preview, :fastly_purge_wait, @fastly_purge_wait), 2)

    {:ok, 200, _, _} = post("service/#{service_id}/purge", body)

    Task.Supervisor.start_child(Preview.Tasks, fn ->
      Process.sleep(sleep_time)
      {:ok, 200, _, _} = post("service/#{service_id}/purge", body)
      Process.sleep(sleep_time)
      {:ok, 200, _, _} = post("service/#{service_id}/purge", body)
    end)

    :ok
  end

  defp auth(), do: Application.get_env(:preview, :fastly_key)

  defp post(url, body) do
    url = @fastly_url <> url

    headers = [
      {"fastly-key", auth()},
      {"accept", "application/json"},
      {"content-type", "application/json"}
    ]

    body = Jason.encode!(body)

    Preview.HTTP.retry("fastly", url, fn -> Preview.HTTP.post(url, headers, body) end)
    |> decode_body()
  end

  defp decode_body({:ok, status, headers, body}) do
    body =
      case Jason.decode(body) do
        {:ok, map} -> map
        {:error, _} -> body
      end

    {:ok, status, headers, body}
  end

  defp decode_body({:error, _} = error), do: error
end
