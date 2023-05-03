defmodule Preview do
  require Logger

  @timeout 20_000

  def process_object(key) do
    key
    |> build_message()
    |> send_message()
  end

  def process_all_objects() do
    {:ok, packages} = Preview.Hex.get_versions()

    Enum.flat_map(packages, fn package ->
      Enum.map(package.versions, &"tarballs/#{package.name}-#{&1}.tar")
    end)
    |> batched_send()
  end

  # Remember to call Preview.Queue.update_index_sitemap() when all messages were processed.
  def process_all_sitemaps(paths) do
    paths
    |> Stream.map(&%{"preview:sitemap" => &1})
    |> Task.async_stream(&send_message/1, max_concurrency: 10, ordered: false, timeout: @timeout)
    |> Stream.run()
  end

  def process_all_latest_versions() do
    {:ok, versions} = Preview.Hex.get_versions()

    Task.async_stream(
      versions,
      fn %{name: name, versions: versions} ->
        version = versions |> Enum.map(&Version.parse!/1) |> Preview.Utils.latest_version()
        Logger.info("Setting latest version: #{name} #{version}")
        Preview.Bucket.update_latest_version(name, version)
      end,
      max_concurrency: 10,
      ordered: false, timeout: @timeout
    )
    |> Stream.run()
  end

  defp build_message(key) do
    %{
      "Records" => [%{"eventName" => "ObjectCreated:Put", "s3" => %{"object" => %{"key" => key}}}]
    }
  end

  defp batched_send(keys) do
    keys
    |> Stream.map(&build_message/1)
    |> Task.async_stream(&send_message/1, max_concurrency: 10, ordered: false, timeout: @timeout)
    |> Stream.run()
  end

  defp send_message(map) do
    queue = Application.fetch_env!(:preview, :queue_id)
    message = Jason.encode!(map)
    do_send_message(queue, message)
  end

  if Mix.env() == :prod do
    defp do_send_message(queue, message) do
      ExAws.SQS.send_message(queue, message)
      |> ExAws.request!()
    end
  else
    defp do_send_message(_queue, message) do
      ref = Broadway.test_message(Preview.Queue, message)

      receive do
        {:ack, ^ref, [_], []} ->
          :ok
      after
        1000 ->
          raise "message timeout"
      end
    end
  end
end
