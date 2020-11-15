defmodule SwaggerWrapperTest do
  use ExUnit.Case

  import Mox

  @base_url "https://api.example.com/api/v3"

  defp sample_http_response do
    {:ok, %HTTPoison.Response{status_code: 200, body: Poison.encode!(%{message: "hello world"})}}
  end

  defp expected_body do
    %{"message" => "hello world"}
  end

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

    test "with query params" do
      assert Kernel.function_exported?(TestWrapper, :test_with_query_params, 3)
    end

    test "with both params" do
      assert Kernel.function_exported?(TestWrapper, :test_with_both_params, 5)
    end
  end

  describe "should create http request" do
    test "test" do
      expect(Http.Mock, :get, fn @base_url <> "/test" ->
        sample_http_response()
      end)

      assert {:ok, response} = TestWrapper.test([])
      assert expected_body() == response.body
    end

    test "test_hello" do
      expect(Http.Mock, :get, fn @base_url <> "/test/1/hello" ->
        sample_http_response()
      end)

      assert {:ok, response} = TestWrapper.test_hello("1", [])
      assert expected_body() == response.body
    end

    test "test_hello_world" do
      expect(Http.Mock, :get, fn @base_url <> "/test/1/hello/blah/world" ->
        sample_http_response()
      end)

      assert {:ok, response} = TestWrapper.test_hello_world("1", "blah", [])
      assert expected_body() == response.body
    end

    test "test_with_query_params" do
      expect(Http.Mock, :get, fn @base_url <> "/test/with/query/params?address=hello&id=1" ->
        sample_http_response()
      end)

      assert {:ok, response} = TestWrapper.test_with_query_params("1", "hello", [])
      assert expected_body() == response.body
    end

    test "test_with_both_params" do
      expect(Http.Mock, :get, fn @base_url <>
                                   "/test/1/with/blah/both/params?enabled=true&message=hello" ->
        sample_http_response()
      end)

      assert {:ok, response} = TestWrapper.test_with_both_params("1", "blah", "hello", "true", [])
      assert expected_body() == response.body
    end
  end
end
