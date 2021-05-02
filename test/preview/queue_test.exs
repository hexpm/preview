defmodule Preview.QueueTest do
  use ExUnit.Case
  alias Preview.{Bucket, Fake, Storage}

  @repo_bucket Application.get_env(:preview, :repo_bucket)
  @preview_bucket Application.get_env(:preview, :preview_bucket)

  test "put object" do
    package = Fake.random(:package)

    Mox.set_mox_global()

    Mox.expect(Preview.HexMock, :get_names, fn ->
      packages = [
        %{
          name: package,
          updated_at: %{seconds: DateTime.utc_now() |> DateTime.to_unix(), nanos: 0}
        }
      ]

      {:ok, packages}
    end)

    Mox.expect(Preview.HexMock, :get_package, fn _ ->
      releases = [
        %{version: "1.0.0"}
      ]

      {:ok, releases}
    end)

    key = "tarballs/#{package}-1.0.0.tar"
    tarball = create_tar(package, "1.0.0", [{"lib/foo.exs", "Foo"}])
    Storage.put(@repo_bucket, key, tarball)

    ref = Broadway.test_message(Preview.Queue, put_message(key))
    assert_receive {:ack, ^ref, [_], []}, 1000

    assert Bucket.get_file_list(package, "1.0.0") == ["lib/foo.exs"]
    assert Bucket.get_file(package, "1.0.0", "lib/foo.exs") == "Foo"

    assert Storage.get(@preview_bucket, "sitemaps/#{package}.xml") =~
             "<loc>http://localhost:5005/preview/#{package}/show/lib/foo.exs</loc>"

    assert Storage.get(@preview_bucket, "sitemaps/sitemap.xml") =~
             "<loc>http://localhost:5005/preview/#{package}/sitemap.xml</loc>"
  end

  test "delete object" do
    Mox.set_mox_global()

    Mox.expect(Preview.HexMock, :get_names, fn ->
      {:ok, []}
    end)

    package = Fake.random(:package)
    key = "tarballs/#{package}-1.0.0.tar"
    Bucket.put_files(package, "1.0.0", [{"README.md", "readme"}])

    ref = Broadway.test_message(Preview.Queue, delete_message(key))
    assert_receive {:ack, ^ref, [_], []}, 1000

    refute Bucket.get_file_list(package, "1.0.0")
    refute Bucket.get_file(package, "1.0.0", "README.md")

    assert Storage.get(@preview_bucket, "sitemaps/sitemap.xml") =~ "<sitemapindex"
  end

  defp put_message(key) do
    Jason.encode!(%{
      "Records" => [
        %{
          "eventName" => "ObjectCreated:Put",
          "s3" => %{"object" => %{"key" => key}}
        }
      ]
    })
  end

  defp delete_message(key) do
    Jason.encode!(%{
      "Records" => [
        %{
          "eventName" => "ObjectRemoved:Delete",
          "s3" => %{"object" => %{"key" => key}}
        }
      ]
    })
  end

  defp create_tar(name, version, files) do
    meta = %{"name" => name, "version" => version}

    files =
      Enum.map(files, fn {filename, contents} -> {String.to_charlist(filename), contents} end)

    {:ok, %{tarball: tarball}} = :hex_tarball.create(meta, files)
    tarball
  end
end
