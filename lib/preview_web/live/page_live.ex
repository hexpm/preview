defmodule PreviewWeb.PageLive do
  use PreviewWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", result: nil, results: %{})}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  def handle_event("search_" <> suggestion, _params, socket) do
    send(self(), {:search, suggestion})
    {:noreply, assign(socket, query: suggestion)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  def handle_event(
        "select_version",
        %{"_target" => ["from"], "from" => from},
        %{assigns: %{results: results}} = socket
      ) do
    IO.inspect(results)
    index_of_selected_from = Enum.find_index(results, &(&1 == from)) || 0
    to_releases = Enum.slice(results, (index_of_selected_from + 1)..-1)

    {:noreply,
     assign(socket,
       from: from,
       to_releases: to_releases
     )}
  end

  def handle_event("go", _params, %{assigns: %{result: result, from: from}} = socket)
      when is_binary(result) and is_binary(from) do
    {:noreply, redirect(socket, to: build_url(result, from))}
  end

  def handle_event("go", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:search, query}, socket) do
    {:noreply, assign(socket, results: search(query), result: query, query: query)}
  end

  def disabled(things) when is_list(things) do
    if Enum.any?(things, &(!&1)) do
      "disabled"
    else
      ""
    end
  end

  def disabled(thing), do: disabled([thing])

  def selected(x, x), do: "selected=selected"
  def selected(_, _), do: ""

  defp search(query) do
    if not PreviewWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end

  defp build_url(app, from), do: "/preview/#{app}/#{from}"
end
