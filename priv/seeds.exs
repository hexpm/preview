{:ok, {200, _, data}} = :hex_repo.get_tarball(:hex_core.default_config(), "decimal", "2.0.0")
Preview.Storage.put(Application.fetch_env!(:preview, :repo_bucket), "tarballs/decimal-2.0.0.tar", data)
Broadway.test_message(Preview.Queue, Jason.encode!(%{"Records" => [%{"eventName" => "ObjectCreated:Put", "s3" => %{"object" => %{"key" => "tarballs/decimal-2.0.0.tar"}}}]}))
