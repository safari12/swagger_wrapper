defmodule Http.Behaviour do
  @typep url :: binary()
  @typep headers :: []

  @callback get(url, headers) :: {:ok, map()} | {:error, binary() | map()}
end
