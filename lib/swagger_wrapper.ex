defmodule SwaggerWrapper do
  defmacro __using__(opts) do
    filepath = opts[:filepath]

    quote do
      import unquote(__MODULE__)
    end

    # generate_test_function(:test)

    with {:ok, json} <- read_json_file(filepath) do
      generate_path_functions(json)
    else
      err -> err
    end
  end

  def generate_test_function(fn_name) do
    quote do
      def unquote(fn_name)(unquote_splicing([Macro.var(:id, nil)])) do
        IO.inspect(unquote(Macro.var(:id, nil)))
        # IO.inspect(id)
        # IO.inspect(arg2)
      end
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
            params = json["paths"][p]["get"]["parameters"]
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

            quote do
              def unquote(String.to_atom(name))(
                    unquote_splicing(param_macros ++ query_param_macros)
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

  defp get_query_params(params) do
    case params do
      nil ->
        []

      ps ->
        ps
        |> Enum.filter(fn p ->
          p["in"] == "query"
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
