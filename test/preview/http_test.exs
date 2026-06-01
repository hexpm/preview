defmodule Preview.HTTPTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, base: "http://localhost:#{bypass.port}"}
  end

  test "post returns status, headers, body", %{bypass: bypass, base: base} do
    Bypass.expect_once(bypass, "POST", "/x", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert body == "payload"
      assert Plug.Conn.get_req_header(conn, "x-key") == ["v"]
      Plug.Conn.resp(conn, 201, "ok")
    end)

    assert {:ok, 201, _, "ok"} =
             Preview.HTTP.post(base <> "/x", [{"x-key", "v"}], "payload")
  end
end
