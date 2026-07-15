defmodule Preview.ApplicationTest do
  use ExUnit.Case, async: true

  alias Preview.Application

  test "queue children can be disabled without removing the web endpoint" do
    enabled = child_ids(Application.children(true))
    disabled = child_ids(Application.children(false))

    assert Preview.Queue in enabled
    assert Preview.Debouncer in enabled
    refute Preview.Queue in disabled
    refute Preview.Debouncer in disabled
    assert PreviewWeb.Endpoint in enabled
    assert PreviewWeb.Endpoint in disabled
  end

  test "disabled production configuration does not require queue credentials" do
    elixir = System.find_executable("elixir")
    erl = System.find_executable("erl")
    path = [Path.dirname(elixir), Path.dirname(erl), "/usr/bin", "/bin"] |> Enum.uniq()

    env = [
      "PATH=#{Enum.join(path, ":")}",
      "PREVIEW_QUEUE_ENABLED=false",
      "PREVIEW_HOST=preview.hex.pm",
      "PREVIEW_REPO_URL=https://repo.hex.pm",
      "PREVIEW_REPO_PUBLIC_KEY=public-key",
      "PREVIEW_BUCKET=preview-bucket",
      "PREVIEW_PORT=4005",
      "PREVIEW_SECRET_KEY_BASE=secret-key-base",
      "PREVIEW_SENTRY_DSN=sentry-dsn",
      "PREVIEW_ENV=prod",
      "BEAM_PORT=14005"
    ]

    expression = ~S|Config.Reader.read!("config/runtime.exs", env: :prod); IO.write("configured")|

    assert {"configured", 0} =
             System.cmd(System.find_executable("env"), ["-i" | env] ++ [elixir, "-e", expression])
  end

  test "production configuration defaults to an enabled queue" do
    env = runtime_env() ++ queue_env()

    expression =
      ~S"""
      config = Config.Reader.read!("config/runtime.exs", env: :prod)
      preview = config[:preview]
      ex_aws = config[:ex_aws]

      IO.write(
        Enum.join(
          [
            preview[:queue_id],
            preview[:queue_concurrency],
            preview[:fastly_key],
            preview[:fastly_repo],
            preview[:repo_bucket][:name],
            ex_aws[:access_key_id],
            ex_aws[:secret_access_key]
          ],
          "|"
        )
      )
      """

    assert {"queue|10|fastly-key|fastly-repo|repo-bucket|aws-key|aws-secret", 0} =
             System.cmd(
               System.find_executable("env"),
               ["-i" | env] ++ [System.find_executable("elixir"), "-e", expression]
             )
  end

  test "production configuration rejects invalid queue settings" do
    env = ["PREVIEW_QUEUE_ENABLED=invalid" | runtime_env()]
    expression = ~S|Config.Reader.read!("config/runtime.exs", env: :prod)|

    assert {output, status} =
             System.cmd(
               System.find_executable("env"),
               ["-i" | env] ++ [System.find_executable("elixir"), "-e", expression],
               stderr_to_stdout: true
             )

    assert status != 0
    assert output =~ "invalid PREVIEW_QUEUE_ENABLED"
  end

  defp runtime_env do
    elixir = System.find_executable("elixir")
    erl = System.find_executable("erl")
    path = [Path.dirname(elixir), Path.dirname(erl), "/usr/bin", "/bin"] |> Enum.uniq()

    [
      "PATH=#{Enum.join(path, ":")}",
      "PREVIEW_HOST=preview.hex.pm",
      "PREVIEW_REPO_URL=https://repo.hex.pm",
      "PREVIEW_REPO_PUBLIC_KEY=public-key",
      "PREVIEW_BUCKET=preview-bucket",
      "PREVIEW_PORT=4005",
      "PREVIEW_SECRET_KEY_BASE=secret-key-base",
      "PREVIEW_SENTRY_DSN=sentry-dsn",
      "PREVIEW_ENV=prod",
      "BEAM_PORT=14005"
    ]
  end

  defp queue_env do
    [
      "PREVIEW_QUEUE_ID=queue",
      "PREVIEW_QUEUE_CONCURRENCY=10",
      "PREVIEW_FASTLY_KEY=fastly-key",
      "PREVIEW_FASTLY_REPO=fastly-repo",
      "PREVIEW_REPO_BUCKET=repo-bucket",
      "PREVIEW_AWS_ACCESS_KEY_ID=aws-key",
      "PREVIEW_AWS_ACCESS_KEY_SECRET=aws-secret"
    ]
  end

  defp child_ids(children) do
    MapSet.new(children, fn child -> Supervisor.child_spec(child, []).id end)
  end
end
