defmodule Preview.Hex.Adapter do
  @behaviour :hex_http

  @opts [follow_redirect: true, max_redirect: 5]

  @impl true
  def request(:get, uri, req_headers, _req_body, _config) do
    req_headers = prepare_headers(req_headers, nil)

    {:ok, status, resp_headers, resp_body} =
      Preview.HTTP.retry("hex_adapter", fn -> Preview.HTTP.get(uri, req_headers, @opts) end)

    # :hex_core expects headers to be a Map
    resp_headers = Map.new(resp_headers)
    {:ok, {status, resp_headers, resp_body}}
  end

  def request(:put, uri, req_headers, req_body, _config) do
    {content_type, payload} = deconstruct_body(req_body)
    req_headers = prepare_headers(req_headers, content_type)

    {:ok, status, resp_headers, resp_body} =
      Preview.HTTP.retry("hex_adapter", fn ->
        Preview.HTTP.put(uri, req_headers, payload, @opts)
      end)

    # :hex_core expects headers to be a Map
    resp_headers = Map.new(resp_headers)
    {:ok, {status, resp_headers, resp_body}}
  end

  defp prepare_headers(req_headers, content_type) do
    if content_type do
      req_headers
      |> Map.put("content-type", content_type)
    else
      req_headers
    end
    |> Enum.to_list()
  end

  defp deconstruct_body(:undefined), do: {nil, ""}
  defp deconstruct_body(body), do: body
end
