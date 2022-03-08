defmodule TestWrapper do
  use SwaggerWrapper,
    filepath: "test/assets/test_swagger.json",
    http_adapter: Application.get_env(:swagger_wrapper, :http_adapter),
    base_url: "https://api.example.com/api/v3",
    headers: [project_id: "test"]
end
