defmodule PreviewWeb.SearchLive do
  use PreviewWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", result: nil, results: %{})}
  end

  # captures when user starts typing in the search box
  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  # captures when user clicks on a suggestion
  def handle_event("search_" <> suggestion, _params, socket) do
    send(self(), {:search, suggestion})
    {:noreply, assign(socket, query: suggestion)}
  end

  # captures when user selects a version from the option menu
  def handle_event(
        "select_version",
        %{"_target" => ["from"], "from" => from},
        socket
      ) do
    {:noreply,
     assign(socket,
       from: from
     )}
  end

  # captures when user clicks the 'preview' button after selecting a version
  def handle_event("go", _params, %{assigns: %{result: result, from: from}} = socket)
      when is_binary(result) and is_binary(from) do
    {:noreply, redirect(socket, to: build_url(result, from))}
  end

  # captures when a user clicks on the preview button before setting a version
  def handle_event("go", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  # handles when user clicks on a suggested package
  def handle_info({:search, query}, socket) do
    {:ok, versions} = Preview.Package.Store.get_versions(query)
    versions = Enum.reverse(versions)
    from = List.first(versions)
    {:noreply, assign(socket, versions: versions, from: from, result: query, query: query)}
  end

  # handles when user is searching
  defp search(query) do
    package_names = Preview.Package.Store.get_names()
    starts_with = package_starts_with(package_names, query)

    cond do
      length(starts_with) >= 10 ->
        starts_with

      true ->
        similar_to = package_similar_to(package_names, query)
        Enum.concat(starts_with, similar_to) |> Enum.uniq()
    end
    |> Enum.take(10)
  end

  defp package_starts_with(package_names, query) do
    package_names
    |> Enum.filter(&String.starts_with?(&1, query))
    |> Enum.sort()
  end

  defp package_similar_to(package_names, query) do
    package_names
    |> Stream.map(&{&1, String.jaro_distance(query, &1)})
    |> Stream.filter(fn
      {_, value} -> value > 0.8
    end)
    |> Enum.sort(fn {_, v1}, {_, v2} -> v1 > v2 end)
    |> Enum.map(&elem(&1, 0))
  end

  defp build_url(app, from), do: "/preview/#{app}/#{from}"
end
