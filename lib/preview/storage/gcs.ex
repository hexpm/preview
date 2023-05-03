defmodule Preview.Storage.GCS do
  @behaviour Preview.Storage.Preview
  @gs_xml_url "https://storage.googleapis.com"

  import SweetXml, only: [sigil_x: 2]
  require Logger

  @impl true
  def get(bucket, key, _opts) do
    url = url(bucket, key)

    case Preview.HTTP.retry("gcs", fn -> Preview.HTTP.get(url, headers()) end) do
      {:ok, 200, _headers, body} -> body
      {:ok, 404, _headers, _body} -> nil
    end
  end

  @impl true
  def list(bucket, prefix) do
    list_stream(bucket, prefix)
  end

  @impl true
  def put(bucket, key, body, opts) do
    url = url(bucket, key)

    headers =
      headers() ++
        meta_headers(Keyword.fetch!(opts, :meta)) ++
        [
          {"cache-control", Keyword.fetch!(opts, :cache_control)},
          {"content-type", Keyword.get(opts, :content_type)}
        ]

    headers = filter_nil_values(headers)

    case Preview.HTTP.retry("gcs", fn -> Preview.HTTP.put(url, headers, body) end) do
      {:ok, 200, _headers, _body} ->
        Logger.info("file upload success #{url}")
        :ok

      {:ok, status, headers, body} ->
        raise "file upload error #{url}\nstatus: #{status} headers: #{inspect(headers)} body: #{inspect(body)}"

      {:error, reason} ->
        raise "file upload error #{url}\nreason: #{inspect(reason)}"
    end
  end

  @impl true
  def delete_many(bucket, keys) do
    keys
    |> Task.async_stream(
      &delete(bucket, &1),
      max_concurrency: 10,
      timeout: 10_000
    )
    |> Preview.Utils.raise_async_stream_error()
    |> Stream.run()
  end

  defp delete(bucket, key) do
    url = url(bucket, key)

    {:ok, 204, _headers, _body} =
      Preview.HTTP.retry("gcs", fn -> Preview.HTTP.delete(url, headers()) end)

    :ok
  end

  defp list_stream(bucket, prefix) do
    start_fun = fn -> nil end
    after_fun = fn _ -> nil end

    next_fun = fn
      :halt ->
        {:halt, nil}

      marker ->
        {items, marker} = do_list(bucket, prefix, marker)
        {items, marker || :halt}
    end

    Stream.resource(start_fun, next_fun, after_fun)
  end

  defp do_list(bucket, prefix, marker) do
    url = url(bucket) <> "?prefix=#{prefix}&marker=#{marker}"

    {:ok, 200, _headers, body} =
      Preview.HTTP.retry("gs", fn -> Preview.HTTP.get(url, headers()) end)

    doc = SweetXml.parse(body)
    marker = SweetXml.xpath(doc, ~x"/ListBucketResult/NextMarker/text()"s)
    items = SweetXml.xpath(doc, ~x"/ListBucketResult/Contents/Key/text()"ls)
    marker = if marker != "", do: marker

    {Enum.map(items, &URI.decode/1), marker}
  end

  defp headers() do
    {:ok, token} = Goth.fetch(Preview.Goth)
    [{"authorization", "#{token.type} #{token.token}"}]
  end

  defp url(bucket) do
    @gs_xml_url <> "/" <> bucket
  end

  defp url(bucket, key) do
    url(bucket) <> "/" <> URI.encode(key)
  end

  defp filter_nil_values(keyword) do
    Enum.reject(keyword, fn {_key, value} -> is_nil(value) end)
  end

  defp meta_headers(meta) do
    Enum.map(meta, fn {key, value} ->
      {"x-goog-meta-#{key}", value}
    end)
  end
end
