defmodule Preview.CDN.Local do
  @behaviour Preview.CDN

  def purge_key(_service, _key), do: :ok
end
