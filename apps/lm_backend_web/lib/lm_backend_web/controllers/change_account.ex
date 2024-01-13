defmodule LmBackendWeb.Controllers.ChangeAccount do
  use LmBackendWeb, :controller

  def index(conn, params) do
    to_account_id = params["account_id"]
    user = get_session(conn, :user)
    allowed_account_ids = LmBackend.Accounts.account_ids_for(user)
    if to_account_id in allowed_account_ids do
      account = LmBackend.Accounts.get_account!(to_account_id)
      conn
      |> put_session(:account, account)
      |> put_flash(:info, "Changed active account to #{account.name || account.id}")
      |> redirect(to: "/")
    else
      conn
      |> put_flash(:error, "Not a valid account for this user")
      |> redirect(to: "/")
    end
  end
end
