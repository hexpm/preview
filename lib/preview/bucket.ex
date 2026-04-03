defmodule Preview.Bucket do
  def get_tarball_to_file(package, version) do
    bucket = Application.get_env(:preview, :repo_bucket)
    key = "tarballs/#{package}-#{version}.tar"
    path = Preview.TmpDir.tmp_file("tarball")

    case Preview.Storage.get_to_file(bucket, key, path) do
      :ok -> {:ok, path}
      nil -> :error
    end
  end

  def put_files(package, version, dir, file_paths) do
    bucket = Application.get_env(:preview, :preview_bucket)

    original_file_list =
      Preview.Storage.list(bucket, Path.join(["files", package, version]) <> "/")

    file_list_key = Path.join("file_lists", "#{package}-#{version}.json")
    file_list_data = Jason.encode!(file_paths)
    Preview.Storage.put(bucket, file_list_key, file_list_data, put_opts(package, version))

    file_entries =
      Enum.map(file_paths, fn filename ->
        {Path.join(["files", package, version, filename]), filename}
      end)

    file_entries
    |> Task.async_stream(
      fn {key, filename} ->
        source = Path.join(dir, filename)
        opts = put_opts(package, version) ++ content_type(filename)
        Preview.Storage.put_file(bucket, key, source, opts)
      end,
      max_concurrency: 10,
      timeout: 10_000
    )
    |> Preview.Utils.raise_async_stream_error()
    |> Stream.run()

    new_keys = Enum.map(file_entries, &elem(&1, 0))
    delete_old_files(Enum.to_list(original_file_list), new_keys)
  end

  def delete_files(package, version) do
    bucket = Application.get_env(:preview, :preview_bucket)
    key = Path.join("file_lists", "#{package}-#{version}.json")

    if files = Preview.Storage.get(bucket, key) do
      files = Jason.decode!(files)
      keys = Enum.map(files, &Path.join(["files", package, version, &1]))

      Preview.Storage.delete_many(bucket, [key | keys])
    end
  end

  def get_file_list(package, version) do
    bucket = Application.get_env(:preview, :preview_bucket)
    key = Path.join("file_lists", "#{package}-#{version}.json")

    if json = Preview.Storage.get(bucket, key) do
      json
      |> Jason.decode!()
      |> Enum.uniq()
    end
  end

  def get_file(package, version, filename) do
    bucket = Application.get_env(:preview, :preview_bucket)
    key = Path.join(["files", package, version, filename])
    Preview.Storage.get(bucket, key)
  end

  def file_size(package, version, filename) do
    bucket = Application.get_env(:preview, :preview_bucket)
    key = Path.join(["files", package, version, filename])

    case Preview.Storage.head(bucket, key) do
      {200, headers} ->
        case headers["content-length"] do
          nil -> nil
          size -> String.to_integer(size)
        end

      nil ->
        nil
    end
  end

  defp delete_old_files(original_file_list, new_file_list) do
    bucket = Application.get_env(:preview, :preview_bucket)
    Preview.Storage.delete_many(bucket, original_file_list -- new_file_list)
  end

  def upload_index_sitemap(sitemap) do
    upload_sitemap("sitemaps/sitemap.xml", "preview/sitemap", sitemap)
  end

  def upload_package_sitemap(package, sitemap) do
    upload_sitemap("sitemaps/#{package}.xml", "preview/package/#{package}", sitemap)
  end

  defp upload_sitemap(path, key, sitemap) do
    bucket = Application.get_env(:preview, :preview_bucket)
    :ok = Preview.Storage.put(bucket, path, sitemap, put_opts(key))
  end

  def update_latest_version(package, version) do
    bucket = Application.fetch_env!(:preview, :preview_bucket)
    key = Path.join("latest_versions", package)

    :ok =
      Preview.Storage.put(
        bucket,
        key,
        to_string(version),
        put_opts("preview/package/#{package}")
      )
  end

  def get_latest_version(package) do
    bucket = Application.fetch_env!(:preview, :preview_bucket)
    key = Path.join("latest_versions", package)
    Preview.Storage.get(bucket, key)
  end

  defp put_opts(package, version) do
    put_opts("preview/package/#{package}/version/#{version}")
  end

  defp put_opts(key) do
    meta = [
      {"surrogate-key", "preview #{key}"},
      {"surrogate-control", "public, max-age=604800"}
    ]

    [cache_control: "public, max-age=3600", meta: meta]
  end

  defp content_type(path) do
    case Path.extname(path) do
      "." <> ext -> [content_type: MIME.type(ext)]
      "" -> []
    end
  end
end
