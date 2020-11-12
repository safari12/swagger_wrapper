defmodule TestWrapper do
  use SwaggerWrapper,
    filepath: "coingecko_swagger.json",
    http_adapter: Application.get_env(:swagger_wrapper, :http_adapter)
end
