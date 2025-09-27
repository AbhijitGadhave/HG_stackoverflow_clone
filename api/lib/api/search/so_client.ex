defmodule Api.Search.SoClient do
  @moduledoc "Thin client for Stack Exchange API using Req."
  @site Application.compile_env(:api, :stackexchange)[:site]
  @key  Application.compile_env(:api, :stackexchange)[:key]

  @search_url  "https://api.stackexchange.com/2.3/search/advanced"
  @answers_url "https://api.stackexchange.com/2.3/questions/{ids}/answers"

  def search_and_answers!(question) do
    %{"items" => questions} =
      Req.get!(@search_url,
        finch: ApiFinch,
        params: [order: "desc", sort: "relevance", q: question, site: @site, key: @key, pagesize: 5]
      ).body

    ids = questions |> Enum.map(& &1["question_id"]) |> Enum.join(";")
    if ids == "", do: []

    %{"items" => answers} =
      Req.get!(
        String.replace(@answers_url, "{ids}", ids),
        finch: ApiFinch,
        params: [order: "desc", sort: "votes", site: @site, key: @key, filter: "withbody", pagesize: 20]
      ).body

    Enum.map(answers, fn a ->
      %{
        "answer_id"   => a["answer_id"],
        "question_id" => a["question_id"],
        "score"       => a["score"],
        "is_accepted" => a["is_accepted"],
        "body"        => a["body"],
        "owner"       => a["owner"]["display_name"]
      }
    end)
  end
end
