defmodule Api.Search.Reranker do
  @moduledoc "Rerank answers using an OpenAI-compatible Chat Completions API."
  @api_base Application.compile_env(:api, :llm)[:api_base]
  @api_key  Application.compile_env(:api, :llm)[:api_key]
  @model   Application.compile_env(:api, :llm)[:model]

  @headers [{"authorization", "Bearer #{@api_key}"}, {"content-type", "application/json"}]

  @prompt """
  You are a strict technical judge. Given a user question and a list of StackOverflow answers (HTML bodies),
  return ONLY a JSON array of answer_id in the best order (most accurate/relevant first).
  """

  def rerank!(question, answers) when is_list(answers) do
    content = %{
      question: question,
      answers: Enum.map(answers, fn a ->
        %{answer_id: a["answer_id"], score: a["score"], is_accepted: a["is_accepted"], body: a["body"]}
      end)
    }

    body = %{
      model: @model,
      messages: [
        %{role: "system", content: @prompt},
        %{role: "user",   content: Jason.encode!(content)}
      ],
      temperature: 0.1
    }

    with {:ok, resp} <- safe_post("#{@api_base}/chat/completions", body),
         text when is_binary(text) <- get_in(resp, ["choices", Access.at(0), "message", "content"]),
         {:ok, ids} when is_list(ids) <- Jason.decode(text) do
      by_id = Map.new(answers, &{&1["answer_id"], &1})
      ids |> Enum.map(&by_id[&1]) |> Enum.filter(& &1)
    else
      _ -> answers
    end
  end

  defp safe_post(url, json) do
    try do
      {:ok, Req.post!(url, finch: ApiFinch, headers: @headers, json: json).body}
    rescue
      _ -> {:error, :post_failed}
    end
  end
end
