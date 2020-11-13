defmodule SwaggerWrapperTest do
  use ExUnit.Case

  import Mox

  alias Http.Mock

  describe "should generate wrapper functions" do
    test "test with arity 1" do
      assert Kernel.function_exported?(TestWrapper, :test, 1)
    end

    test "test_hello with arity 2" do
      assert Kernel.function_exported?(TestWrapper, :test_hello, 2)
    end

    test "test_hello_world with arity 3" do
      assert Kernel.function_exported?(TestWrapper, :test_hello_world, 3)
    end
  end

  # test "should generate ping" do
  #   expect(Mock, :get, fn _url ->
  #     {:ok, %HTTPoison.Response{status_code: 200, body: Poison.encode!(%{message: "pong"})}}
  #   end)

  #   assert {:ok, %{body: %{"message" => "pong"}}} = TestWrapper.test([])
  # end
end
