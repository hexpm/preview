defmodule Preview.Utils do
  @moduledoc false

  def latest_version(package) when is_binary(package) do
    {:ok, releases} = Preview.Hex.get_package(package)
    releases |> Enum.map(&Version.parse!(&1.version)) |> latest_version()
  end

  def latest_version(versions) do
    stable_versions = Enum.filter(versions, &(&1.pre == []))

    if stable_versions == [] do
      latest(versions)
    else
      latest(stable_versions)
    end
  end

  defp latest([]), do: nil

  defp latest(versions) do
    Enum.reduce(versions, fn version, latest ->
      if Version.compare(version, latest) == :lt do
        latest
      else
        version
      end
    end)
  end

  def raise_async_stream_error(stream) do
    Stream.each(stream, fn
      {:ok, _} -> :ok
      {:exit, {error, stacktrace}} -> reraise(error, stacktrace)
    end)
  end
end
