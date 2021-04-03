defmodule PreviewWeb.SyntaxHighlighing do
  def language_class(filename) do
    "language-" <> class_for(Path.extname(filename), filename)
  end

  defp class_for(".md", _), do: "markdown"
  defp class_for(_, "README"), do: "markdown"
  defp class_for(_, "readme"), do: "markdown"
  defp class_for(".ex", _), do: "elixir"
  defp class_for(".exs", _), do: "elixir"
  defp class_for(".erl", _), do: "erlang"
  defp class_for(".hrl", _), do: "erlang"
  defp class_for(".escript", _), do: "erlang"
  defp class_for(_, "rebar.config"), do: "erlang"
  defp class_for(_, "rebar.config.script"), do: "erlang"

  defp class_for(_, filename) do
    cond do
      String.ends_with?(filename, ".app.src") -> "erlang"
      true -> "unsupported"
    end
  end
end
