defmodule PreviewWeb.PackageControllerTest do
  use PreviewWeb.ConnCase, async: true

  describe "GET /preview/:package/:version/raw/*filename" do
    test "file exists", %{conn: conn} do
      files = [{"foo.txt", "foo"}]
      :ok = Preview.Bucket.put_files("foo", "1.0.0", files)

      conn = get(conn, "/preview/foo/1.0.0/raw/foo.txt")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert conn.resp_body == "foo"
    end

    test "content-type is set for .ex", %{conn: conn} do
      files = [{"foo.exs", "1 + 2"}, {"foo.bin", ""}]
      :ok = Preview.Bucket.put_files("foo", "1.0.0", files)

      conn = get(conn, "/preview/foo/1.0.0/raw/foo.exs")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert conn.resp_body == "1 + 2"
    end

    test "content-type is not set for other files", %{conn: conn} do
      files = [{"foo.bin", ""}]
      :ok = Preview.Bucket.put_files("foo", "1.0.0", files)

      conn = get(conn, "/preview/foo/1.0.0/raw/foo.bin")
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == []
    end

    @tag :capture_log
    test "file does not exists", %{conn: conn} do
      conn = get(conn, "/preview/foo/1.0.0/raw/bad")
      assert conn.status == 404
      assert conn.resp_body == "not found"
    end
  end
end
