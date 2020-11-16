repo_bucket = Application.fetch_env!(:preview, :repo_bucket)
{:ok, {200, _, data}} = :hex_repo.get_tarball(:hex_core.default_config(), "decimal", "2.0.0")
Preview.Storage.put(repo_bucket, "tarballs/decimal-2.0.0.tar", data)

message = %{
  "Records" => [
    %{
      "eventName" => "ObjectCreated:Put",
      "s3" => %{"object" => %{"key" => "tarballs/decimal-2.0.0.tar"}}
    }
  ]
}

ref = Broadway.test_message(Preview.Queue, Jason.encode!(message))

receive do
  {:ack, ^ref, [_], []} -> :ok
after
  1000 ->
    raise "message timeout"
end
