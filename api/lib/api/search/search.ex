defmodule Api.Search do
  import Ecto.Query
  alias Api.Repo
  alias Api.Search.{SearchQuery, SoClient, Reranker}

  def search_and_cache!(anon_id, question) do
    original = SoClient.search_and_answers!(question)
    reranked = Reranker.rerank!(question, original)

    {:ok, _} =
      %SearchQuery{}
      |> SearchQuery.changeset(%{
        anon_id: anon_id,
        question: question,
        original_answers: %{items: original},
        reranked_answers: %{items: reranked}
      })
      |> Repo.insert()

    from(s in SearchQuery, where: s.anon_id == ^anon_id, order_by: [desc: s.inserted_at])
    |> Repo.all()
    |> Enum.drop(5)
    |> Enum.each(&Repo.delete!/1)

    %{original: original, reranked: reranked}
  end

  def recent(anon_id) do
    from(s in SearchQuery,
      where: s.anon_id == ^anon_id,
      order_by: [desc: s.inserted_at],
      limit: 5,
      select: %{question: s.question, at: s.inserted_at}
    )
    |> Repo.all()
  end
end
