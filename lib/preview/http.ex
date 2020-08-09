defmodule Preview.HTTP do
  @max_retry_times 5
  @base_sleep_time 100

  require Logger

  def get(url, headers, opts \\ []) do
    Finch.build(:get, url, headers)
    |> Finch.request(PreviewFinch, opts)
    |> read_response()
  end

  def put(url, headers, body, opts \\ []) do
    Finch.build(:put, url, headers, body)
    |> Finch.request(PreviewFinch, opts)
    |> read_response()
  end

  def get_stream(url, headers) do
    Finch.stream(Finch.build(:get, url, headers), PreviewFinch, %{}, fn
      {:status, status}, acc -> IO.inspect(status)
      {:headers, headers}, acc -> IO.inspect(headers)
      {:data, data}, acc -> IO.inspect(data)
    end)
  end

  def put_stream(url, headers, stream) do
    Finch.stream(Finch.build(:put, url, headers, stream), PreviewFinch, %{}, fn
      {:status, status}, acc -> IO.inspect(status)
      {:headers, headers}, acc -> IO.inspect(headers)
      {:data, data}, acc -> IO.inspect(data)
    end)
  end

  defp read_response(result) do
    case result do
      {:ok, %{body: body, headers: headers, status: status}} -> {:ok, status, headers, body}
    end
  end

  def retry(service, fun) do
    retry(fun, service, 0)
  end

  defp retry(fun, service, times) do
    case fun.() do
      {:ok, status, _headers, _body} when status in 500..599 ->
        do_retry(fun, service, times, "status #{status}")

      {:error, reason} ->
        do_retry(fun, service, times, reason)

      result ->
        result
    end
  end

  defp do_retry(fun, service, times, reason) do
    Logger.warn("#{service} API ERROR: #{inspect(reason)}")

    if times + 1 < @max_retry_times do
      sleep = trunc(:math.pow(3, times) * @base_sleep_time)
      :timer.sleep(sleep)
      retry(fun, service, times + 1)
    else
      {:error, reason}
    end
  end
end
