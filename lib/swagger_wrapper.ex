defmodule SwaggerWrapper do
  defmacro __using__(opts) do
    filepath = opts[:filepath]

    quote do
      import unquote(__MODULE__)
    end

    with {:ok, json} <- read_json_file(filepath) do
      generate_path_functions(json)
    else
      err -> err
    end
  end

  def generate_path_functions(json) do
    base_url = "https://#{json["host"]}#{json["basePath"]}"

    json["paths"]
    |> Map.keys()
    |> Enum.filter(fn p ->
      json["paths"][p]["get"] != nil
    end)
    |> Enum.map(fn path ->
      path
      |> (fn p ->
            info = json["paths"][p]["get"]
            params = info["parameters"]
            params_doc = get_params_doc(params)
            path_params = get_path_params(params)
            query_params = get_query_params(params)

            param_names =
              path_params
              |> Enum.map(& &1["name"])

            query_param_names =
              query_params
              |> Enum.map(& &1["name"])

            param_patterns =
              param_names
              |> Enum.map(&"/{#{&1}}")

            name =
              p
              |> String.split(["/"] ++ param_patterns, trim: true)
              |> Enum.join("_")

            url = base_url <> p

            param_macros =
              param_names
              |> Enum.map(&Macro.var(String.to_atom(&1), nil))

            query_param_macros =
              query_param_names
              |> Enum.map(&Macro.var(String.to_atom(&1), nil))

            opts = Macro.var(:opts, nil)

            doc = """
              #{info["summary"]}

              #{params_doc}
            """

            quote do
              @doc unquote(doc)
              def unquote(String.to_atom(name))(
                    unquote_splicing(param_macros ++ query_param_macros ++ [opts])
                  ) do
                normalized_url =
                  unquote(param_macros)
                  |> Enum.with_index()
                  |> Enum.reduce(unquote(url), fn {m, i}, acc ->
                    Macro.escape(acc)
                    |> String.replace(
                      "{#{Enum.at(unquote(param_names), i)}}",
                      "#{m}"
                    )
                  end)

                full_url =
                  unquote(query_param_macros)
                  |> Enum.with_index()
                  |> Enum.reduce(%{}, fn {q, i}, acc ->
                    Map.put(acc, Enum.at(unquote(query_param_names), i), q)
                  end)
                  |> Map.merge(Enum.into(unquote(opts), %{}))
                  |> URI.encode_query()
                  |> (fn x ->
                        case x do
                          "" ->
                            normalized_url

                          _ ->
                            normalized_url <> "?#{x}"
                        end
                      end).()

                HTTPoison.get(Macro.escape(full_url))
              end
            end
          end).()
    end)
  end

  defp get_path_params(params) do
    case params do
      nil ->
        []

      ps ->
        ps
        |> Enum.filter(fn p ->
          p["in"] == "path"
        end)
    end
  end

  defp get_params_doc(params) do
    case params do
      nil ->
        ""

      ps ->
        ps
        |> Enum.reduce("##Parameters\n", fn x, acc ->
          description = String.replace(x["description"], ~r/<(.|\n)*?>/, "")
          acc <> "- #{x["name"]}: #{description}\n"
        end)
    end
  end

  defp get_query_params(params) do
    case params do
      nil ->
        []

      ps ->
        ps
        |> Enum.filter(fn p ->
          p["in"] == "query" and p["required"] == true
        end)
    end
  end

  def read_json_file(filepath) do
    with {:ok, body} <- File.read(filepath),
         {:ok, json} <- Poison.decode(body) do
      {:ok, json}
    else
      err -> err
    end
  end
end
