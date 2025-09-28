defmodule Api.Search.SearchQuery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "search_queries" do
    field :anon_id, :string
    field :question, :string
    field :original_answers, :map
    field :reranked_answers, :map
    timestamps(updated_at: false)
  end

  def changeset(sq, attrs) do
    sq
    |> cast(attrs, [:anon_id, :question, :original_answers, :reranked_answers])
    |> validate_required([:anon_id, :question])
  end
end
