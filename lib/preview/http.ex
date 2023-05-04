defmodule Preview.HTTP do
  @max_retry_times 5
  @base_sleep_time 200

  require Logger

  def get(url, headers, opts \\ []) do
    Finch.build(:get, url, headers)
    |> Finch.request(Preview.Finch, opts)
    |> read_response()
  end

  def put(url, headers, body, opts \\ []) do
    Finch.build(:put, url, headers, body)
    |> Finch.request(Preview.Finch, opts)
    |> read_response()
  end

  def delete(url, headers, opts \\ []) do
    Finch.build(:delete, url, headers)
    |> Finch.request(Preview.Finch, opts)
    |> read_response()
  end

  defp read_response(result) do
    case result do
      {:ok, %{body: body, headers: headers, status: status}} -> {:ok, status, headers, body}
      {:error, reason} -> {:error, reason}
    end
  end

  def retry(service, url, fun) do
    retry(fun, service, url, 0)
  end

  defp retry(fun, service, url, times) do
    case fun.() do
      {:ok, status, _headers, _body} when status in 500..599 or status == 429 ->
        do_retry(fun, service, url, times, "status #{status}")

      {:error, reason} ->
        do_retry(fun, service, url, times, reason)

      result ->
        result
    end
  end

  defp do_retry(fun, service, url, times, reason) do
    Logger.warning("#{service} HTTP ERROR #{url}: #{inspect(reason)}")

    if times + 1 < @max_retry_times do
      sleep = trunc(:math.pow(3, times) * @base_sleep_time)
      Process.sleep(sleep)
      retry(fun, service, url, times + 1)
    else
      {:error, reason}
    end
  end
end
