import Config

config :swagger_wrapper,
  http_adapter: HTTPoison

import_config "#{Mix.env()}.exs"
