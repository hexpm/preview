defmodule Preview.CDN do
  @type service :: atom
  @type key :: String.t()

  @callback purge_key(service, key | [key]) :: :ok

  defp impl(), do: Application.get_env(:preview, :cdn_impl)

  def purge_key(service, key), do: impl().purge_key(service, key)
end
