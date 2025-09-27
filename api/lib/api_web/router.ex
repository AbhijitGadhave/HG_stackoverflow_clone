defmodule ApiWeb.Router do
  use ApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["*"]
    plug :fetch_cookies 
    plug :assign_anon_id  
  end

  scope "/api", ApiWeb do
    pipe_through :api
    get "/recent", RecentController, :index
    get "/search", QuestionController, :index
  end

  defp assign_anon_id(conn, _opts) do
    case conn.cookies["anon_id"] do
      nil ->
        id = Base.url_encode64(:crypto.strong_rand_bytes(6))
        conn
        |> put_resp_cookie("anon_id", id, max_age: 60*60*24*365, same_site: "Lax", http_only: false)
        |> assign(:anon_id, id)

      v ->
        assign(conn, :anon_id, v)
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
