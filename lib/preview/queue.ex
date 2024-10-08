defmodule Preview.Queue do
  use Broadway
  require Logger

  @gcs_put_debounce Application.compile_env!(:preview, :gcs_put_debounce)

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
          max_number_of_messages: concurrency,
          wait_time_seconds: 10,
          visibility_timeout: 120
        },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: concurrency,
          min_demand: 0,
          max_demand: 1
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

        files =
          Enum.flat_map(contents, fn {path, blob} ->
            case safe_charlist_path(path) do
              {:ok, path} ->
                [{path, blob}]

              :error ->
                Logger.error("Unsafe path from #{package} #{version}: #{path}")
                []
            end
          end)
          # Handle old packages with broken, non-unique files
          |> Enum.uniq_by(fn {path, _blob} -> path end)
          |> Enum.sort()

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
    start = System.os_time(:millisecond)
    key = s3["object"]["key"]
    Logger.info("OBJECT CREATED #{key}")

    case key_components(key) do
      {:ok, package, version} ->
        files = create_package(package, version)

        if Version.compare(Preview.Utils.latest_version(package), version) == :eq do
          Preview.Debouncer.debounce(
            Preview.Debouncer,
            {:latest_version, package},
            @gcs_put_debounce,
            fn ->
              Preview.Bucket.update_latest_version(package, version)
            end
          )

          update_package_sitemap(package, files)
          update_index_sitemap()
        end

        purge_key(package, version)
        elapsed = System.os_time(:millisecond) - start
        Logger.info("FINISHED UPLOADING CONTENTS #{key} #{elapsed}ms")

      :error ->
        :skip
    end
  end

  defp handle_record(%{"eventName" => "ObjectRemoved:" <> _, "s3" => s3}) do
    start = System.os_time(:millisecond)
    key = s3["object"]["key"]
    Logger.info("OBJECT DELETED #{key}")

    case key_components(key) do
      {:ok, package, version} ->
        delete_package(package, version)
        update_index_sitemap()
        purge_key(package, version)

        elapsed = System.os_time(:millisecond) - start
        Logger.info("FINISHED DELETING CONTENTS #{key} #{elapsed}ms")
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
      Enum.flat_map(tarball_contents.contents, fn {path, blob} ->
        case safe_charlist_path(path) do
          {:ok, path} ->
            [{path, blob}]

          :error ->
            Logger.error("Unsafe path from #{package} #{version}: #{path}")
            []
        end
      end)
      # Handle old packages with broken, non-unique files
      |> Enum.uniq_by(fn {path, _blob} -> path end)
      |> Enum.sort()

    Preview.Bucket.put_files(package, version, files)
    files
  end

  def delete_package(package, version) do
    Preview.Bucket.delete_files(package, version)
  end

  @doc false
  def update_index_sitemap() do
    Logger.info("UPDATING INDEX SITEMAP")

    Preview.Debouncer.debounce(Preview.Debouncer, :sitemap_index, @gcs_put_debounce, fn ->
      {:ok, packages} = Preview.Hex.get_names()
      body = Preview.Sitemaps.render_index(packages)
      Preview.Bucket.upload_index_sitemap(body)
    end)

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
    Preview.CDN.purge_key(:fastly_repo, [
      "preview/sitemap",
      "preview/package/#{package}",
      "preview/package/#{package}/version/#{version}"
    ])
  end

  defp safe_charlist_path(list) do
    case list |> List.to_string() |> Path.split() |> safe_path([]) do
      {:ok, path} -> {:ok, Path.join(path)}
      :error -> :error
    end
  end

  defp safe_path(["." | rest], acc), do: safe_path(rest, acc)
  defp safe_path([".." | rest], [_prev | acc]), do: safe_path(rest, acc)
  defp safe_path([".." | _rest], []), do: :error
  defp safe_path([path | rest], acc), do: safe_path(rest, [path | acc])
  defp safe_path([], []), do: :error
  defp safe_path([], acc), do: {:ok, Enum.reverse(acc)}
end
