defmodule Preview.Storage.Local do
  @behaviour Preview.Storage.Preview

  @impl true
  def list(bucket, prefix) do
    path(bucket, prefix <> "**")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, path(bucket)))
  end

  @impl true
  def get(bucket, key, _opts) do
    case File.read(path(bucket, key)) do
      {:ok, content} -> content
      {:error, _} -> nil
    end
  end

  def get_to_file(bucket, key, dest, _opts) do
    source = path(bucket, key)

    if File.regular?(source) do
      File.cp!(source, dest)
      :ok
    else
      nil
    end
  end

  @impl true
  def put(bucket, key, body, _opts) do
    path = path(bucket, key)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end

  @impl true
  def put_file(bucket, key, source, _opts) do
    path = path(bucket, key)
    File.mkdir_p!(Path.dirname(path))
    File.cp!(source, path)
  end

  @impl true
  def delete_many(bucket, keys) do
    Enum.each(keys, &File.rm_rf!(path(bucket, &1)))
  end

  defp path(bucket) do
    Path.join(Application.get_env(:preview, :tmp_dir), bucket)
  end

  defp path(bucket, key) do
    Path.join(path(bucket), key)
  end
end
