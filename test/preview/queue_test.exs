defmodule Preview.QueueTest do
  use ExUnit.Case, async: true
  alias Preview.{Bucket, Fake, Storage}

  @repo_bucket Application.get_env(:preview, :repo_bucket)
  @preview_bucket Application.get_env(:preview, :preview_bucket)

  defp create_tar(name, version, files) do
    meta = %{"name" => name, "version" => version}

    files =
      Enum.map(files, fn {filename, contents} -> {String.to_charlist(filename), contents} end)

    {:ok, %{tarball: tarball}} = :hex_tarball.create(meta, files)
    tarball
  end

  test "put object" do
    Mox.set_mox_global()

    Mox.expect(Preview.HexpmMock, :get_package, fn _package ->
      %{"releases" => []}
    end)

    Mox.expect(Preview.HexpmMock, :preview_sitemap, fn ->
      "the sitemap"
    end)

    package = Fake.random(:package)
    key = "tarballs/#{package}-1.0.0.tar"
    tarball = create_tar(package, "1.0.0", [{"lib/foo.exs", "Foo"}])
    Storage.put(@repo_bucket, key, tarball)

    ref = Broadway.test_message(Preview.Queue, put_message(key))
    assert_receive {:ack, ^ref, [_], []}

    assert Bucket.get_file_list(package, "1.0.0") == ["lib/foo.exs"]
    assert Bucket.get_file(package, "1.0.0", "lib/foo.exs") == "Foo"

    assert Storage.get(@preview_bucket, "sitemaps/#{package}-1.0.0.xml") =~
             "<loc>http://localhost:5005/preview/#{package}/1.0.0/show/lib/foo.exs</loc>"

    assert Storage.get(@preview_bucket, "sitemaps/sitemap.xml") == "the sitemap"
  end

  test "delete object" do
    package = Fake.random(:package)
    key = "tarballs/#{package}-1.0.0.tar"
    Bucket.put_files(package, "1.0.0", [{"README.md", "readme"}])

    ref = Broadway.test_message(Preview.Queue, delete_message(key))
    assert_receive {:ack, ^ref, [_], []}

    refute Bucket.get_file_list(package, "1.0.0")
    refute Bucket.get_file(package, "1.0.0", "README.md")
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
end
