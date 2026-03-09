defmodule Preview.TmpDirTest do
  use ExUnit.Case, async: true

  test "tmp_file/1 creates a file" do
    path = Preview.TmpDir.tmp_file("test")
    assert File.exists?(path)
    assert File.regular?(path)
  end

  test "tmp_dir/1 creates a directory" do
    path = Preview.TmpDir.tmp_dir("test")
    assert File.dir?(path)
  end

  test "cleanup on normal process exit" do
    test_pid = self()

    Task.start(fn ->
      file = Preview.TmpDir.tmp_file("test")
      dir = Preview.TmpDir.tmp_dir("test")
      send(test_pid, {:paths, file, dir})
    end)

    assert_receive {:paths, file, dir}
    Process.sleep(100)

    refute File.exists?(file)
    refute File.exists?(dir)
  end

  @tag :capture_log
  test "cleanup on process crash" do
    test_pid = self()

    Task.start(fn ->
      file = Preview.TmpDir.tmp_file("test")
      dir = Preview.TmpDir.tmp_dir("test")
      send(test_pid, {:paths, file, dir})
      raise "crash"
    end)

    assert_receive {:paths, file, dir}
    Process.sleep(100)

    refute File.exists?(file)
    refute File.exists?(dir)
  end

  test "multiple paths for one process" do
    test_pid = self()

    Task.start(fn ->
      paths =
        for i <- 1..5 do
          file = Preview.TmpDir.tmp_file("test-#{i}")
          dir = Preview.TmpDir.tmp_dir("test-#{i}")
          {file, dir}
        end

      send(test_pid, {:paths, paths})
    end)

    assert_receive {:paths, paths}
    Process.sleep(100)

    for {file, dir} <- paths do
      refute File.exists?(file)
      refute File.exists?(dir)
    end
  end

  test "paths persist while process is alive" do
    file = Preview.TmpDir.tmp_file("test")
    dir = Preview.TmpDir.tmp_dir("test")

    assert File.exists?(file)
    assert File.dir?(dir)
  end
end
