defmodule Api.Repo.Migrations.CreateSearchQueries do
  use Ecto.Migration

  def change do
    create table(:search_queries) do
      add :anon_id, :string, null: false
      add :question, :text, null: false
      add :original_answers, :map
      add :reranked_answers, :map
      timestamps(updated_at: false)
    end

    create index(:search_queries, [:anon_id, :inserted_at])
  end
end
