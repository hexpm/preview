defmodule Preview.Queue do
  use Broadway
  require Logger

  def start_link(_opts) do
    url = Application.fetch_env!(:preview, :queue_id)
    producer = Application.fetch_env!(:preview, :queue_producer)
    concurrency = Application.fetch_env!(:preview, :queue_concurrency)

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
          concurrency: concurrency,
          min_demand: 1,
          max_demand: concurrency
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

  def handle_message(%{data: %{"preview:sitemap" => key}} = message) do
    Logger.info("#{key}: start")

    case key_components(key) do
      {:ok, package, version} ->
        {:ok, tarball} = Preview.Bucket.get_tarball(package, version)
        {:ok, %{contents: contents}} = Preview.Hex.unpack_tarball(tarball, :memory)
        files = for {path, data} <- contents, do: {List.to_string(path), data}
        update_package_sitemap(package, files)
        Logger.info("#{key}: done")

      :error ->
        Logger.info("#{key}: skip")
    end

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
        files = create_package(package, version)

        if Version.compare(Preview.Utils.latest_version(package), version) == :eq do
          Preview.Bucket.update_latest_version(package, version)
          update_index_sitemap()
          update_package_sitemap(package, files)
        end

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
        delete_package(package, version)
        update_index_sitemap()
        Logger.info("FINISHED DELETING CONTENTS #{key}")
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

  def create_package(package, version) do
    # TODO: Handle errors
    # TODO: This does not handle symlinks
    {:ok, tarball} = Preview.Bucket.get_tarball(package, version)
    {:ok, tarball_contents} = Preview.Hex.unpack_tarball(tarball, :memory)

    files =
      Enum.map(tarball_contents.contents, fn {filename, blob} ->
        {List.to_string(filename), blob}
      end)

    Preview.Bucket.put_files(package, version, files)
    purge_key(package, version)
    files
  end

  def delete_package(package, version) do
    Preview.Bucket.delete_files(package, version)
    purge_key(package, version)
  end

  @doc false
  def update_index_sitemap() do
    Logger.info("UPDATING INDEX SITEMAP")

    {:ok, packages} = Preview.Hex.get_names()
    body = Preview.Sitemaps.render_index(packages)
    Preview.Bucket.upload_index_sitemap(body)

    Logger.info("UPDATED INDEX SITEMAP")
  end

  defp update_package_sitemap(package, files) do
    Logger.info("UPDATING PACKAGE SITEMAP #{package}")

    files = for {path, _content} <- files, do: path
    body = Preview.Sitemaps.render_package(package, files, DateTime.utc_now())
    Preview.Bucket.upload_package_sitemap(package, body)

    Logger.info("UPDATED PACKAGE SITEMAP #{package}")
  end

  @doc false
  def paths_for_sitemaps() do
    repo_bucket = Application.fetch_env!(:preview, :repo_bucket)
    key_regex = ~r"tarballs/(.*)-(.*).tar$"

    Preview.Storage.list(repo_bucket, "tarballs/")
    |> Stream.filter(&Regex.match?(key_regex, &1))
    |> Stream.map(fn path ->
      {package, version} = filename_to_release(path)
      {path, package, Version.parse!(version)}
    end)
    |> Stream.chunk_by(fn {_, package, _} -> package end)
    |> Stream.flat_map(fn entries ->
      entries = Enum.sort_by(entries, fn {_, _, version} -> version end, {:desc, Version})
      all_versions = for {_, _, version} <- entries, do: version

      List.wrap(
        Enum.find_value(entries, fn {path, _, version} ->
          Version.compare(Preview.Utils.latest_version(all_versions), version) == :eq && path
        end)
      )
    end)
  end

  defp purge_key(package, version) do
    Preview.CDN.purge_key(:fastly_repo, "preview/#{package}/#{version}")
  end
end
