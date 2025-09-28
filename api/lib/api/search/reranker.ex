defmodule Api.Search.Reranker do
  
  require Logger

  defp llm_cfg, do: Application.get_env(:api, :llm, [])

  defp llm_api_base do
    llm_cfg()
    |> Keyword.get(:api_base, "http://localhost:11434/v1")
    |> String.trim_trailing("/")
  end

  defp llm_model,   do: Keyword.get(llm_cfg(), :model, "llama3:8b")
  defp llm_api_key, do: Keyword.get(llm_cfg(), :api_key)

  defp headers do
    base = [{"content-type", "application/json"}]

    case llm_api_key() do
      nil -> base
      key -> [{"authorization", "Bearer #{key}"} | base]
    end
  end

  @system_prompt """
  You are a strict JSON API.

  Task:
  Given a question and a list of answers, return ONLY a JSON array of ALL answer_id integers,
  ordered best-first by:
  1) factual correctness for the question,
  2) direct relevance and clarity of explanation,
  3) runnable code/examples and completeness,
  4) community signals (accepted=true, higher score) as tie-breakers.

  Rules:
  - Include EVERY answer_id exactly once (no duplicates, no omissions).
  - Output must be just a JSON array of integers. No extra text, no code fences, no keys.

  Example:
  [59353516, 59319461, 77078736]
  """

  defp build_user_payload(question, answers) do
    trimmed =
      answers
      |> Enum.map(fn a ->
        %{
          answer_id: a["answer_id"],
          score: a["score"],
          is_accepted: a["is_accepted"],
          # keep body short & plaintext; helps small models stay on-task
          body:
            a["body"]
            |> strip_html()
            |> String.slice(0, 240)
        }
      end)

    Jason.encode!(%{question: question, answers: trimmed})
  end

  defp strip_html(body) when is_binary(body) do
    body
    |> String.replace(~r/<[^>]*>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp strip_html(_), do: ""

  def rerank!(question, answers) when is_list(answers) do
    user_content = build_user_payload(question, answers)

    body = %{
      model: llm_model(),
      messages: [
        %{role: "system", content: @system_prompt},
        %{role: "user", content: user_content}
      ],
      temperature: 0
    }

    url_v1 = llm_api_base() <> "/chat/completions"
    url_legacy = (llm_api_base() |> String.replace_suffix("/v1", "")) <> "/api/chat"

    with {:ok, resp} <- safe_post(url_v1, body),
         {:ok, ids} <- extract_ids_from_v1(resp) do
      final_ids = ensure_full_coverage(ids, answers)
      reorder_by_ids(answers, final_ids)
    else
      _v1_error ->
        Logger.warning("v1/chat/completions failed or non-JSON array; trying legacy /api/chat")

        legacy_body = Map.put(body, :stream, false)

        case safe_post(url_legacy, legacy_body) do
          {:ok, resp} ->
            case extract_ids_from_legacy(resp) do
              {:ok, ids} ->
                final_ids = ensure_full_coverage(ids, answers)
                reorder_by_ids(answers, final_ids)

              _ ->
                warn_and_fallback(resp, answers)
            end

          err ->
            Logger.error("Legacy /api/chat failed: #{inspect(err)}")
            fallback_sort(answers)
        end
    end
  end

  defp safe_post(url, json) do
    try do
      resp =
        Req.post!(
          url,
          finch: ApiFinch,
          headers: headers(),
          json: json,
          receive_timeout: 60_000
        )

      {:ok, resp.body}
    rescue
      e ->
        Logger.error("HTTP request failed: #{inspect(e)}")
        {:error, :post_failed}
    end
  end

  defp extract_ids_from_v1(%{"choices" => [%{"message" => %{"content" => text}} | _]}) do
    extract_json_array_of_ints(text)
  end

  defp extract_ids_from_v1(_), do: {:error, :bad_v1_shape}

  defp extract_ids_from_legacy(%{"message" => %{"content" => text}}) do
    extract_json_array_of_ints(text)
  end

  defp extract_ids_from_legacy(_), do: {:error, :bad_legacy_shape}

  defp extract_json_array_of_ints(text) when is_binary(text) do
    case Jason.decode(text) do
      {:ok, list} when is_list(list) ->
        if list_of_ints?(list), do: {:ok, list}, else: {:error, :not_ints}

      _ ->
        # try to find the first [...]-looking array in the text
        case Regex.run(~r/\[[^\]]*\]/s, text) do
          [json] ->
            case Jason.decode(json) do
              {:ok, list} when is_list(list) ->
                if list_of_ints?(list), do: {:ok, list}, else: {:error, :json_not_int_array}

              other ->
                {:error, {:json_decode_error, other}}
            end

          _ ->
            {:error, :no_json_array_found}
        end
    end
  end

  defp extract_json_array_of_ints(_), do: {:error, :non_binary_text}

  defp list_of_ints?(list), do: Enum.all?(list, fn x -> is_integer(x) end)

  defp ensure_full_coverage(ids, answers) when is_list(ids) do
    ids_set = MapSet.new(ids)
    all_ids = Enum.map(answers, & &1["answer_id"])
    missing = Enum.filter(all_ids, fn id -> not MapSet.member?(ids_set, id) end)
    uniq_preserve(ids ++ missing)
  end

  defp uniq_preserve(list) do
    {out, _seen} =
      Enum.reduce(list, {[], MapSet.new()}, fn x, {acc, seen} ->
        if MapSet.member?(seen, x) do
          {acc, seen}
        else
          {[x | acc], MapSet.put(seen, x)}
        end
      end)

    Enum.reverse(out)
  end

  defp reorder_by_ids(answers, ids) when is_list(ids) do
    by_id = Map.new(answers, &{&1["answer_id"], &1})

    ordered =
      ids
      |> Enum.map(&Map.get(by_id, &1))
      |> Enum.reject(&is_nil/1)

    case ordered do
      [] -> answers
      list -> list
    end
  end

  defp fallback_sort(answers) do
    Enum.sort_by(
      answers,
      fn a ->
        score = a["score"] || 0
        accepted = if a["is_accepted"], do: 1, else: 0
        body = a["body"] || ""
        code_bonus =
          if String.contains?(body, "```") or String.contains?(body, "<code>"), do: 1, else: 0
        {accepted, score, code_bonus}
      end,
      :desc
    )
  end

  defp warn_and_fallback(resp, answers) do
    Logger.warning(
      "LLM returned non-JSON / incomplete array; using heuristic fallback. Resp: #{inspect(resp)}"
    )

    fallback_sort(answers)
  end
end
