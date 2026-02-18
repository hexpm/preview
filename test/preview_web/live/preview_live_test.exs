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

  describe "mount/3" do
    setup [:setup_package]

    test "filename from path segments", %{conn: conn, package: package, version: version} do
      {:ok, view, _html} =
        live(conn, "/preview/#{package}/#{version}/show/lib/foo.ex")

      assert render(view) =~ "<h2>lib/foo.ex</h2>"
    end

    test "filename from query parameter", %{conn: conn, package: package, version: version} do
      {:ok, view, _html} =
        live(conn, "/preview/#{package}/#{version}?filename=include%2Fheader.hrl")

      assert render(view) =~ "<h2>include/header.hrl</h2>"
    end

    test "default file when no filename given", %{conn: conn, package: package, version: version} do
      {:ok, view, _html} =
        live(conn, "/preview/#{package}/#{version}")

      assert render(view) =~ "<h2>README.md</h2>"
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
