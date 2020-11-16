defmodule Preview.Queue do
  use Broadway
  require Logger

  def start_link(_opts) do
    url = Application.fetch_env!(:preview, :queue_id)
    producer = Application.fetch_env!(:preview, :queue_producer)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          producer,
          queue_url: url,
          max_number_of_messages: 8,
          wait_time_seconds: 10,
          visibility_timeout: 120
        },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 2,
          min_demand: 1,
          max_demand: 2
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, %Broadway.Message{} = message, _context) do
    message
    |> Broadway.Message.update_data(&Jason.decode!/1)
    |> handle_message()
  end

  @doc false
  def handle_message(%{data: %{"Event" => "s3:TestEvent"}} = message) do
    message
  end

  def handle_message(%{data: %{"Records" => records}} = message) do
    Enum.each(records, &handle_record/1)
    message
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    messages
  end

  defp handle_record(%{"eventName" => "ObjectCreated:" <> _, "s3" => s3}) do
    key = s3["object"]["key"]
    Logger.info("OBJECT CREATED #{key}")

    case key_components(key) do
      {:ok, package, version} ->
        # TODO: Handle errors
        # TODO: This does not handle symlinks
        {:ok, tarball} = Preview.Bucket.get_tarball(package, version)
        {:ok, tarball_contents} = Preview.Hex.unpack_tarball(tarball, :memory)

        files =
          Enum.map(tarball_contents.contents, fn {filename, blob} ->
            {List.to_string(filename), blob}
          end)

        Preview.Bucket.put_files(package, version, files)

        Logger.info("FINISHED UPLOADING CONTENTS #{key}")

      :error ->
        :skip
    end
  end

  defp handle_record(%{"eventName" => "ObjectRemoved:" <> _, "s3" => s3}) do
    key = s3["object"]["key"]
    Logger.info("OBJECT DELETED #{key}")

    case key_components(key) do
      {:ok, package, version} ->
        Logger.info("FINISHED DELETING CONTENTS #{key}")
        Preview.Bucket.delete_files(package, version)
        :ok

      :error ->
        :skip
    end
  end

  defp key_components(key) do
    case Path.split(key) do
      ["tarballs", file] ->
        {package, version} = filename_to_release(file)
        {:ok, package, version}

      _ ->
        :error
    end
  end

  defp filename_to_release(file) do
    base = Path.basename(file, ".tar")
    [package, version] = String.split(base, "-", parts: 2)
    {package, version}
  end
end
