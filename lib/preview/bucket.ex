defmodule Preview.Bucket do
  def get_tarball(package, version) do
    bucket = Application.get_env(:preview, :repo_bucket)
    key = "tarballs/#{package}-#{version}.tar"
    Preview.Storage.get(bucket, key)
  end

  def put_files(package, version, files) do
    bucket = Application.get_env(:preview, :preview_bucket)
    file_list = Jason.encode!(Enum.map(files, &elem(&1, 0)))
    file_list = {Path.join("file_lists", "#{package}-#{version}.json"), file_list}

    files =
      Enum.map(files, fn {filename, contents} ->
        {Path.join(["files", package, version, filename]), contents}
      end)

    [file_list | files]
    |> Task.async_stream(
      fn {key, data} ->
        Preview.Storage.put(bucket, key, data)
      end,
      max_concurrency: 10,
      timeout: 10_000
    )
    |> Stream.run()
  end

  def delete_files(package, version) do
    bucket = Application.get_env(:preview, :preview_bucket)
    key = Path.join("file_lists", "#{package}-#{version}.json")

    if files = Preview.Storage.get(bucket, key) do
      files = Jason.decode!(files)
      keys = Enum.map(files, &Path.join(["files", package, version, &1]))

      Preview.Storage.delete_many(bucket, keys)
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
    key = Path.join(["files", package, version, filename])
    Preview.Storage.get(bucket, key)
  end
end
