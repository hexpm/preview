defmodule Preview.BucketTest do
  use ExUnit.Case, async: true
  alias Preview.{Bucket, Fake, Storage}

  @repo_bucket Application.get_env(:preview, :repo_bucket)
  @preview_bucket Application.get_env(:preview, :preview_bucket)

  test "get_tarball/2" do
    package = Fake.random(:package)
    assert Bucket.get_tarball(package, "0.1.0") == :error

    Storage.put(@repo_bucket, "tarballs/#{package}-0.1.0.tar", "data")
    assert Bucket.get_tarball(package, "0.1.0") == {:ok, "data"}
  end

  describe "put_files/3" do
    test "upload files" do
      package = Fake.random(:package)
      files = [{"README.md", "readme"}, {"lib/foo.ex", "foo"}]
      Bucket.put_files(package, "0.1.0", files)

      file_list = Storage.get(@preview_bucket, "file_lists/#{package}-0.1.0.json")
      assert Jason.decode(file_list) == {:ok, ["README.md", "lib/foo.ex"]}

      assert Storage.get(@preview_bucket, "files/#{package}/0.1.0/README.md") == "readme"
      assert Storage.get(@preview_bucket, "files/#{package}/0.1.0/lib/foo.ex") == "foo"
    end

    test "delete old files" do
      package = Fake.random(:package)
      files = [{"README.md", "readme"}, {"lib/foo.ex", "foo"}]
      Bucket.put_files(package, "0.1.0", files)

      files = [{"README.md", "readme"}, {"lib/bar.ex", "bar"}]
      Bucket.put_files(package, "0.1.0", files)

      file_list = Storage.get(@preview_bucket, "file_lists/#{package}-0.1.0.json")
      assert Jason.decode(file_list) == {:ok, ["README.md", "lib/bar.ex"]}

      assert Storage.get(@preview_bucket, "files/#{package}/0.1.0/README.md") == "readme"
      assert Storage.get(@preview_bucket, "files/#{package}/0.1.0/lib/bar.ex") == "bar"
      refute Storage.get(@preview_bucket, "files/#{package}/0.1.0/lib/foo.ex")
    end
  end

  test "delete_files/2" do
    package1 = Fake.random(:package)
    package2 = Fake.random(:package)
    file_list = Jason.encode!(["README.md", "lib/foo.ex"])

    Storage.put(@preview_bucket, "file_lists/#{package1}-0.1.0.json", file_list)
    Storage.put(@preview_bucket, "files/#{package1}/0.1.0/README.md", "readme")
    Storage.put(@preview_bucket, "files/#{package1}/0.1.0/lib/foo.ex", "foo")
    Storage.put(@preview_bucket, "file_lists/#{package2}-0.1.0.json", ~s(["README.md"]))
    Storage.put(@preview_bucket, "files/#{package2}/0.1.0/README.md", "readme")

    Bucket.delete_files(package1, "0.1.0")

    refute Storage.get(@preview_bucket, "file_lists/#{package1}-0.1.0.json")
    refute Storage.get(@preview_bucket, "files/#{package1}/0.1.0/README.md")
    refute Storage.get(@preview_bucket, "files/#{package1}/0.1.0/lib/foo.ex")

    assert Storage.get(@preview_bucket, "file_lists/#{package2}-0.1.0.json")
    assert Storage.get(@preview_bucket, "files/#{package2}/0.1.0/README.md")
  end

  test "get_file_list/2" do
    package = Fake.random(:package)
    Storage.put(@preview_bucket, "file_lists/#{package}-0.1.0.json", ~s(["README.md"]))

    assert Bucket.get_file_list(package, "0.1.0") == ["README.md"]
  end

  test "get_file/3" do
    package = Fake.random(:package)
    Storage.put(@preview_bucket, "files/#{package}/0.1.0/README.md", "readme")

    assert Bucket.get_file(package, "0.1.0", "README.md") == "readme"
    refute Bucket.get_file(package, "0.1.0", "lib/foo.ex")
  end
end
