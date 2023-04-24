defmodule PreviewWeb.Router do
  use PreviewWeb, :router
  use Plug.ErrorHandler
  use PreviewWeb.Plugs.Rollbax

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PreviewWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :raw do
    plug :put_secure_browser_headers
  end

  scope "/", PreviewWeb do
    pipe_through :browser

    get "/sitemap.xml", SitemapController, :index
    get "/preview/:package/sitemap.xml", SitemapController, :package

    live "/", SearchLive, :index
    live "/preview/:package", PreviewLive, :latest
    live "/preview/:package/show/*filename", PreviewLive, :latest
    live "/preview/:package/:version", PreviewLive, :index
    live "/preview/:package/:version/show/*filename", PreviewLive, :index
  end

  scope "/", PreviewWeb do
    pipe_through :raw

    get "/preview/:package/raw/*filename", PackageController, :raw
    get "/preview/:package/:version/raw/*filename", PackageController, :raw
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PreviewWeb.Telemetry
    end
  end
end
