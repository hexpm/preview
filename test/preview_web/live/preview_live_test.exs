defmodule PreviewWeb.PreviewLiveTest do
  use PreviewWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Preview.{Fake, Storage}
  alias PreviewWeb.PreviewLive

  @preview_bucket Application.compile_env(:preview, :preview_bucket)

  defp setup_package(_context) do
    package = Fake.random(:package)
    version = "0.1.0"
    file_list = Jason.encode!(["README.md", "lib/foo.ex", "include/header.hrl"])

    Storage.put(@preview_bucket, "file_lists/#{package}-#{version}.json", file_list)
    Storage.put(@preview_bucket, "files/#{package}/#{version}/README.md", "readme contents")
    Storage.put(@preview_bucket, "files/#{package}/#{version}/lib/foo.ex", "foo contents")

    Storage.put(
      @preview_bucket,
      "files/#{package}/#{version}/include/header.hrl",
      "header contents"
    )

    Storage.put(@preview_bucket, "latest_versions/#{package}", version)

    %{package: package, version: version}
  end

  defp put_package(package, version, filename, contents) do
    file_list = Jason.encode!([filename])

    Storage.put(@preview_bucket, "file_lists/#{package}-#{version}.json", file_list)
    Storage.put(@preview_bucket, "files/#{package}/#{version}/#{filename}", contents)
    Storage.put(@preview_bucket, "latest_versions/#{package}", version)
  end

  describe "syntax highlighting" do
    test "highlights BEAM-language source", %{conn: conn} do
      package = Fake.random(:package)
      version = "0.1.0"
      put_package(package, version, "lib/foo.ex", "defmodule Foo do\n  x = 1\nend\n")

      {:ok, _view, html} = live(conn, "/preview/#{package}/#{version}/show/lib/foo.ex")

      # Highlighting wraps each token in its own <span>, so the source text is
      # no longer contiguous in the output.
      refute html =~ "defmodule Foo do"
    end

    test "renders non-BEAM files as plain text", %{conn: conn} do
      package = Fake.random(:package)
      version = "0.1.0"
      put_package(package, version, "data.json", "[1, 2, 3]\n")

      {:ok, _view, html} = live(conn, "/preview/#{package}/#{version}/show/data.json")

      # JSON is not highlighted, so the contents stay intact.
      assert html =~ "[1, 2, 3]"
    end
  end

  describe "mount/3" do
    setup [:setup_package]

    test "filename from path segments", %{conn: conn, package: package, version: version} do
      {:ok, view, _html} =
        live(conn, "/preview/#{package}/#{version}/show/lib/foo.ex")

      assert has_element?(view, "h2", "lib/foo.ex")
    end

    test "filename from query parameter", %{conn: conn, package: package, version: version} do
      {:ok, view, _html} =
        live(conn, "/preview/#{package}/#{version}?filename=include%2Fheader.hrl")

      assert has_element?(view, "h2", "include/header.hrl")
    end

    test "default file when no filename given", %{conn: conn, package: package, version: version} do
      {:ok, view, _html} =
        live(conn, "/preview/#{package}/#{version}")

      assert has_element?(view, "h2", "README.md")
    end

    test "returns 404 when file list is empty", %{conn: conn} do
      package = Fake.random(:package)
      version = "0.1.0"
      file_list = Jason.encode!([])

      Storage.put(@preview_bucket, "file_lists/#{package}-#{version}.json", file_list)
      Storage.put(@preview_bucket, "latest_versions/#{package}", version)

      exception =
        assert_raise PreviewWeb.PreviewLive.Exception, fn ->
          live(conn, "/preview/#{package}/#{version}")
        end

      assert exception.plug_status == 404
    end
  end

  describe "default_file/1" do
    test "when package contains README" do
      all_files = ~w[mix.exs lib.ex README]
      assert PreviewLive.default_file(all_files) == "README"
    end

    test "when package contains README.txt" do
      all_files = ~w[mix.exs lib.ex README.txt]
      assert PreviewLive.default_file(all_files) == "README.txt"
    end

    test "when package contains README.md" do
      all_files = ~w[mix.exs lib.ex README.md]
      assert PreviewLive.default_file(all_files) == "README.md"
    end

    test "when package contains readme.md" do
      all_files = ~w[mix.exs lib.ex readme.md]
      assert PreviewLive.default_file(all_files) == "readme.md"
    end

    test "when package contains mix.exs" do
      all_files = ~w[.formatter.exs rebar.config mix.exs lib.ex]
      assert PreviewLive.default_file(all_files) == "mix.exs"
    end

    test "when package contains rebar.config" do
      all_files = ~w[.DS-Store rebar.config Makefile lib.ex]
      assert PreviewLive.default_file(all_files) == "rebar.config"
    end

    test "when package contains Makefile" do
      all_files = ~w[lib.ex Makefile 420.jpg]
      assert PreviewLive.default_file(all_files) == "Makefile"
    end

    test "when package does not contain  any of the defaults" do
      all_files = ~w[.formatter.exs lib/app.ex lib/helper.ex]
      assert PreviewLive.default_file(all_files) == ".formatter.exs"
    end
  end
end
