defmodule Preview.Storage.GCS do
  @behaviour Preview.Storage.Preview

  @gs_xml_url "https://storage.googleapis.com"
  @oauth_scope "https://www.googleapis.com/auth/devstorage.read_write"

  import SweetXml, only: [sigil_x: 2]

  def get(bucket, key, _opts) do
    url = url(bucket, key)

    {:ok, status, headers, body} =
      Preview.HTTP.retry("gcs", fn -> Preview.HTTP.get(url, headers()) end)

    {status, headers, body}
  end

  def list(bucket, prefix) do
    list_stream(bucket, prefix)
  end

  def put(bucket, key, body, _opts) do
    url = url(bucket, key)
    Preview.HTTP.retry("gcs", fn -> Preview.HTTP.put(url, headers(), body) end)
  end

  def delete_many(bucket, keys) do
    keys
    |> Task.async_stream(
      &delete(bucket, &1),
      max_concurrency: 10,
      timeout: 10_000
    )
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

    {items, marker}
  end

  defp headers() do
    {:ok, token} = Goth.Token.for_scope(@oauth_scope)
    [{"authorization", "#{token.type} #{token.token}"}]
  end

  defp url(bucket) do
    @gs_xml_url <> "/" <> bucket
  end

  defp url(bucket, key) do
    url(bucket) <> "/" <> key
  end
end
