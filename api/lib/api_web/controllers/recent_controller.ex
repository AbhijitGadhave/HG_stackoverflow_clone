defmodule ApiWeb.RecentController do
  use ApiWeb, :controller
  alias Api.Search

  def index(conn, _params) do
    json(conn, %{recent: Search.recent(conn.assigns.anon_id)})
  end
end
