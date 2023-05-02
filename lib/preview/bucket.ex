defmodule Preview.Bucket do
  def get_tarball(package, version) do
    bucket = Application.get_env(:preview, :repo_bucket)
    key = "tarballs/#{package}-#{version}.tar"

    case Preview.Storage.get(bucket, key) do
      nil -> :error
      blob -> {:ok, blob}
    end
  end

  def put_files(package, version, files) do
    bucket = Application.get_env(:preview, :preview_bucket)

    original_file_list =
      Preview.Storage.list(bucket, Path.join(["files", package, version]) <> "/")

    file_list = Enum.map(files, &elem(&1, 0))

    file_list_path =
      {Path.join("file_lists", "#{package}-#{version}.json"), Jason.encode!(file_list)}

    files =
      Enum.map(files, fn {filename, contents} ->
        {Path.join(["files", package, version, filename]), contents}
      end)

    [file_list_path | files]
    |> Task.async_stream(fn {key, data} -> put_file(bucket, key, data, package, version) end,
      max_concurrency: 10,
      timeout: 10_000
    )
    |> Stream.run()

    delete_old_files(Enum.to_list(original_file_list), Enum.map(files, &elem(&1, 0)))
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
      Jason.decode!(json)
    end
  end

  def get_file(package, version, filename) do
    bucket = Application.get_env(:preview, :preview_bucket)
    key = Path.join(["files", package, version, URI.encode(filename)])
    Preview.Storage.get(bucket, key)
  end

  defp delete_old_files(original_file_list, new_file_list) do
    bucket = Application.get_env(:preview, :preview_bucket)
    Preview.Storage.delete_many(bucket, original_file_list -- new_file_list)
  end

  def upload_index_sitemap(sitemap) do
    upload_sitemap("sitemaps/sitemap.xml", sitemap)
  end

  def upload_package_sitemap(package, sitemap) do
    upload_sitemap("sitemaps/#{package}.xml", sitemap)
  end

  defp upload_sitemap(path, sitemap) do
    opts = []
    bucket = Application.get_env(:preview, :preview_bucket)
    :ok = Preview.Storage.put(bucket, path, sitemap, opts)
  end

  def update_latest_version(package, version) do
    bucket = Application.fetch_env!(:preview, :preview_bucket)
    key = Path.join("latest_versions", package)
    :ok = Preview.Storage.put(bucket, key, to_string(version), [])
  end

  def get_latest_version(package) do
    bucket = Application.fetch_env!(:preview, :preview_bucket)
    key = Path.join("latest_versions", package)
    Preview.Storage.get(bucket, key)
  end

  def put_file(bucket, key, data, package, version) do
    meta = [
      {"surrogate-key", "preview/#{package}/#{version}"},
      {"surrogate-control", "public, max-age=604800"}
    ]

    opts = [cache_control: "public, max-age=3600", meta: meta]
    Preview.Storage.put(bucket, key, data, opts)
  end
end
