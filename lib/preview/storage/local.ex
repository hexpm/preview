defmodule Preview.Storage.Local do
  @behaviour Preview.Storage.Repo
  @behaviour Preview.Storage.Preview

  def list(bucket, prefix) do
    path(bucket, prefix <> "**")
    |> Path.wildcard(match_dot: true)
    |> Enum.map(&Path.relative_to(&1, path(bucket)))
  end

  def get(bucket, key, _opts) do
    case File.read(path(bucket, key)) do
      {:ok, content} -> content
      {:error, _} -> nil
    end
  end

  def put(bucket, key, body, _opts) do
    path = path(bucket, key)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end

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
