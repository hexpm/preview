defmodule Preview.Storage do
  @type package :: String.t()
  @type version :: String.t()
  @type contents :: Enum.t()

  @callback get(package, version) :: {:ok, contents} | {:error, term}
  @callback put(package, version, contents) :: :ok | {:error, term}

  defp impl(), do: Application.get_env(:preview, :storage_impl)

  def get(package, version) do
    impl().get(package, version)
  end

  def put(package, version, contents) do
    impl().put(package, version, contents)
  end
end
