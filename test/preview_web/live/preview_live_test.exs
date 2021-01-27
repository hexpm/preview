defmodule PreviewWeb.PreviewLiveTest do
  use PreviewWeb.ConnCase, async: true

  alias PreviewWeb.PreviewLive

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
      all_files = ~w[.formatter.exs mix.exs lib.ex]
      assert PreviewLive.default_file(all_files) == "mix.exs"
    end

    test "when package contains rebar.config" do
      all_files = ~w[.DS-Store rebar.config lib.ex]
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
