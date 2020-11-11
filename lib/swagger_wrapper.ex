defmodule SwaggerWrapper do
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end

    # generate_sample_function()

    with {:ok, json} <- read_json_file("coingecko_swagger.json") do
      generate_path_functions(json)
    else
      err -> err
    end
  end

  # def generate_sample_function do
  #   1..10
  #   |> Enum.map(fn i ->
  #     quote do
  #       def unquote(String.to_atom("hello_world_#{i}"))() do
  #         unquote("Hello World")
  #       end
  #     end
  #   end)
  # end

  def generate_path_functions(json) do
    json["paths"]
    |> Map.keys()
    |> Enum.filter(fn p ->
      String.contains?(p, "{id}") == false
    end)
    |> Enum.map(fn path ->
      path
      |> (fn p ->
            name =
              p
              |> String.split("/", trim: true)
              |> Enum.join("_")

            url = "https://api.coingecko.com/api/v3" <> p

            quote do
              def unquote(String.to_atom(name))() do
                HTTPoison.get(Macro.escape(unquote(url)))
              end
            end
          end).()
    end)
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
