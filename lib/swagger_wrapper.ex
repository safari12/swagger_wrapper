defmodule SwaggerWrapper do
  defmacro __using__(opts) do
    filepath = opts[:filepath]
    http_adapter = opts[:http_adapter]

    quote do
      import unquote(__MODULE__)
    end

    with {:ok, json} <- read_json_file(filepath) do
      generate_wrapper(json, http_adapter)
    else
      err -> err
    end
  end

  defp generate_wrapper(json, http_adapter) do
    base_url = "https://#{json["host"]}#{json["basePath"]}"

    json["paths"]
    |> Map.keys()
    |> Enum.filter(fn p ->
      json["paths"][p]["get"] != nil
    end)
    |> Enum.map(&generate_wrapper_function(&1, json, base_url, http_adapter))
  end

  defp generate_wrapper_function(path, json, base_url, http_adapter) do
    info = json["paths"][path]["get"]
    params = info["parameters"]
    params_doc = get_params_doc(params)

    path_param_names =
      params
      |> get_path_params()
      |> get_param_names()

    query_param_names =
      params
      |> get_query_params()
      |> get_param_names()

    fn_name = get_wrapper_fn_name(path, path_param_names)
    url = base_url <> path

    param_macro_vars = path_param_names |> get_macro_vars()
    query_macro_vars = query_param_names |> get_macro_vars()
    opts = Macro.var(:opts, nil)

    doc = get_doc(info["summary"], params_doc)

    generate_http_wrapper_function(
      doc,
      url,
      fn_name,
      param_macro_vars,
      path_param_names,
      query_macro_vars,
      query_param_names,
      opts,
      http_adapter
    )
  end

  defp generate_http_wrapper_function(
         doc,
         url,
         fn_name,
         param_macro_vars,
         param_names,
         query_macro_vars,
         query_names,
         opts,
         http_adapter
       ) do
    quote do
      @doc unquote(doc)
      def unquote(String.to_atom(fn_name))(
            unquote_splicing(param_macro_vars ++ query_macro_vars ++ [opts])
          ) do
        normalized_url =
          unquote(param_macro_vars)
          |> Enum.with_index()
          |> Enum.reduce(unquote(url), fn {m, i}, acc ->
            Macro.escape(acc)
            |> String.replace(
              "{#{Enum.at(unquote(param_names), i)}}",
              "#{m}"
            )
          end)

        full_url =
          unquote(query_macro_vars)
          |> Enum.with_index()
          |> Enum.reduce(%{}, fn {q, i}, acc ->
            Map.put(acc, Enum.at(unquote(query_names), i), q)
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

        case unquote(http_adapter).get(Macro.escape(full_url)) do
          {:ok, %{body: body} = response} ->
            {:ok, %{response | body: Poison.decode!(body)}}

          err ->
            err
        end
      end
    end
  end

  defp get_macro_vars(x), do: x |> Enum.map(&Macro.var(String.to_atom(&1), nil))

  defp get_wrapper_fn_name(path, path_param_names) do
    param_patterns =
      path_param_names
      |> Enum.map(&"/{#{&1}}")

    path
    |> String.split(["/"] ++ param_patterns, trim: true)
    |> Enum.join("_")
  end

  defp get_path_params(nil), do: []
  defp get_path_params(params), do: params |> Enum.filter(&(&1["in"] == "path"))

  defp get_query_params(nil), do: []

  defp get_query_params(params),
    do: params |> Enum.filter(&(&1["in"] == "query" && &1["required"] == true))

  defp get_param_names(params), do: params |> Enum.map(& &1["name"])

  defp get_doc(summary, params_doc) do
    """
    #{summary}

    #{params_doc}
    """
  end

  defp get_params_doc(params) do
    case params do
      nil ->
        ""

      ps ->
        ps
        |> Enum.reduce("## Parameters\n", fn x, acc ->
          description = String.replace(x["description"], ~r/<(.|\n)*?>/, "")
          acc <> "- #{x["name"]}: #{description}\n"
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
