defmodule LmBackendWeb.Router do
  use LmBackendWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LmBackendWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :check_api_token
  end

  pipeline :require_user do
    plug :require_user_plug
  end

  pipeline :require_admin_user do
    plug :require_admin_user_plug
  end

  pipeline :require_no_user do
    plug :require_no_user_plug
  end

  scope "/", LmBackendWeb do
    pipe_through :browser
    pipe_through :require_user

    live_session :user, on_mount: {LmBackendWeb.InitAssigns, :user} do
      live "/", Live.Home, :index

      live "/setup", Live.Setup, :index

      live "/self/change_account", SelfLive.ChangeAccount, :index
      get "/self/do_change_account/:account_id", Controllers.ChangeAccount, :index
      live "/self/profile", SelfLive.Profile, :index
      live "/dashboards", DashboardLive.Index, :index
      live "/dashboards/new", DashboardLive.Index, :new
      live "/dashboards/:id", DashboardLive.Show, :show
      live "/dashboards/:id/edit", DashboardLive.Show, :edit
    end
  end

  scope "/", LmBackendWeb do
    pipe_through :browser
    pipe_through :require_admin_user

    live_session :admin_user, on_mount: {LmBackendWeb.InitAssigns, :admin_user} do
    end
  end

  scope "/", LmBackendWeb do
    pipe_through :browser
    pipe_through :require_no_user

    live_session :public, on_mount: {LmBackendWeb.InitAssigns, :public} do
      live "/login", Live.Login
    end
  end

  scope "/auth", LmBackendWeb.Controllers do
    pipe_through :browser

    get "/signout", AuthController, :signout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  scope "/api", LmBackendWeb.Controllers do
    pipe_through :api

    post "/telemetry", TelemetryController, :post
  end


  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:lm_backend_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LmBackendWeb.Telemetry
    end
  end

  def require_user_plug(conn, _opts) do
    user = get_session(conn, :user)

    if is_nil(user) do
      redirect_to_login(conn)
    else
      conn
    end
  end

  def require_admin_user_plug(conn, _opts) do
    # user = get_session(conn, :user)

    # TODO implement
    redirect_to_index(conn)
  end

  def require_no_user_plug(conn, _opts) do
    user = get_session(conn, :user)

    case user do
      nil ->
        conn

      _user ->
        redirect_to_index(conn)
    end
  end

  # Todo: actual login screen with auth provider selection.
  defp redirect_to_login(conn) do
    conn
    |> redirect(to: "/login")
    |> halt()
  end

  defp redirect_to_index(conn) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  defp check_api_token(conn, _opts) do
    token = bearer_token(conn)

    case LmBackend.Accounts.get_owner(token) do
      nil ->
        conn
        |> send_resp(401, ~s({"error": "Forbidden"}))
        |> halt()
      %LmBackend.Accounts.User{} = user ->
        account_ids = LmBackend.Accounts.account_ids_for(user)

        conn
        |> put_session(:user_id, user.id)
        |> put_session(:account_ids, account_ids)
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      [] -> ""
      [h | _] -> h
      |> String.replace("Bearer", "")
      |> String.trim()
    end
  end
end
