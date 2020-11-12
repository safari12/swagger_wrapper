defmodule SwaggerWrapperTest do
  use ExUnit.Case

  import Mox

  alias Http.Mock

  test "should generate ping" do
    expect(Mock, :get, fn _url ->
      {:ok, %HTTPoison.Response{status_code: 200, body: Poison.encode!(%{message: "pong"})}}
    end)

    assert {:ok, %{body: %{"message" => "pong"}}} = TestWrapper.ping([])
  end
end
