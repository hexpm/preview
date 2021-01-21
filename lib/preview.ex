defmodule Preview do
  def process_object(key) do
    key
    |> build_message()
    |> send_message()
  end

  def process_all_objects() do
    Preview.Hex.get_versions()
    |> Enum.flat_map(fn package ->
      Enum.map(package.versions, &"tarballs/#{package.name}/#{&1}.tar")
    end)
    |> batched_send()
  end

  defp build_message(key) do
    %{
      "Records" => [%{"eventName" => "ObjectCreated:Put", "s3" => %{"object" => %{"key" => key}}}]
    }
  end

  defp batched_send(keys) do
    keys
    |> Stream.map(&build_message/1)
    |> Task.async_stream(&send_message/1, max_concurrency: 10, ordered: false)
    |> Stream.run()
  end

  defp send_message(map) do
    queue = Application.fetch_env!(:preview, :queue_id)
    message = Jason.encode!(map)

    ExAws.SQS.send_message(queue, message)
    |> ExAws.request!()
  end
end
