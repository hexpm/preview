defmodule Preview.Storage do
  @type bucket :: atom
  @type prefix :: key
  @type key :: String.t()
  @type body :: binary
  @type opts :: Keyword.t()
  @type status :: 100..599
  @type headers :: %{String.t() => String.t()}

  defmodule Repo do
    @type bucket :: atom
    @type prefix :: key
    @type key :: String.t()
    @type body :: binary
    @type opts :: Keyword.t()

    @callback get(bucket, key, opts) :: body | nil
  end

  defmodule Preview do
    @type bucket :: atom
    @type prefix :: key
    @type key :: String.t()
    @type body :: binary
    @type stream :: Enum.t()
    @type opts :: Keyword.t()
    @type status :: 100..599
    @type headers :: %{String.t() => String.t()}

    @callback get(bucket, key, opts) :: body | nil
    @callback list(bucket, prefix) :: [key]
    @callback put(bucket, key, body, opts) :: term
    @callback delete_many(bucket, [key]) :: [term]
  end

  def list(bucket, prefix) do
    {impl, name} = bucket(bucket)
    impl.list(name, prefix)
  end

  def get(bucket, key, opts \\ []) do
    {impl, name} = bucket(bucket)
    impl.get(name, key, opts)
  end

  def put(bucket, key, body, opts \\ []) do
    {impl, name} = bucket(bucket)
    impl.put(name, key, body, opts)
  end

  def delete_many(bucket, keys) do
    {impl, name} = bucket(bucket)
    impl.delete_many(name, keys)
  end

  defp bucket(bucket) do
    {bucket[:implementation], bucket[:name]}
  end
end
