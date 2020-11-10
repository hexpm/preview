defmodule Preview.Storage.Local do
  @behaviour Preview.Storage.Repo
  @behaviour Preview.Storage.Preview

  def list(bucket, prefix) do
    path(bucket, prefix)
    |> ls()
    |> Enum.filter(&String.starts_with?(&1, prefix))
    |> Enum.map(&Path.join(prefix, &1))
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
    Enum.each(keys, &File.rm!(path(bucket, &1)))
  end

  defp path(bucket, key) do
    Path.join([Application.get_env(:preview, :tmp_dir), bucket, key])
  end

  defp ls(path) do
    case File.ls(path) do
      {:ok, files} -> files
      {:error, _} -> []
    end
  end
end
