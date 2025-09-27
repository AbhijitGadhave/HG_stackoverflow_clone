defmodule ApiWeb.QuestionController do
  use ApiWeb, :controller
  alias Api.Search

  def index(conn, %{"q" => q}) do
    %{original: original, reranked: reranked} = Search.search_and_cache!(conn.assigns.anon_id, q)
    json(conn, %{question: q, original_answers: original, reranked_answers: reranked})
  end

  def index(conn, _), do: json(conn, %{error: "missing q"})
end
