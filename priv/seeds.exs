repo_bucket = Application.fetch_env!(:preview, :repo_bucket)

{:ok, {200, _, data}} = :hex_repo.get_tarball(:hex_core.default_config(), "decimal", "1.9.0")
Preview.Storage.put(repo_bucket, "tarballs/decimal-1.9.0.tar", data)

{:ok, {200, _, data}} = :hex_repo.get_tarball(:hex_core.default_config(), "decimal", "2.0.0")
Preview.Storage.put(repo_bucket, "tarballs/decimal-2.0.0.tar", data)

{:ok, {200, _, data}} = :hex_repo.get_tarball(:hex_core.default_config(), "ecto", "0.2.0")
Preview.Storage.put(repo_bucket, "tarballs/ecto-0.2.0.tar", data)

{:ok, {200, _, data}} = :hex_repo.get_tarball(:hex_core.default_config(), "phoenix_live_view", "1.0.0")
Preview.Storage.put(repo_bucket, "tarballs/phoenix_live_view-1.0.0.tar", data)

message = %{
  "Records" => [
    %{
      "eventName" => "ObjectCreated:Put",
      "s3" => %{"object" => %{"key" => "tarballs/decimal-1.9.0.tar"}}
    },
    %{
      "eventName" => "ObjectCreated:Put",
      "s3" => %{"object" => %{"key" => "tarballs/decimal-2.0.0.tar"}}
    },
    %{
      "eventName" => "ObjectCreated:Put",
      "s3" => %{"object" => %{"key" => "tarballs/ecto-0.2.0.tar"}}
    },
    %{
      "eventName" => "ObjectCreated:Put",
      "s3" => %{"object" => %{"key" => "tarballs/phoenix_live_view-1.0.0.tar"}}
    }
  ]
}

ref = Broadway.test_message(Preview.Queue, Jason.encode!(message))

receive do
  {:ack, ^ref, [_], []} ->
    :ok
after
  10_000 ->
    raise "message timeout"
end

Preview.Queue.paths_for_sitemaps() |> Preview.process_all_sitemaps()
Preview.Queue.update_index_sitemap()
