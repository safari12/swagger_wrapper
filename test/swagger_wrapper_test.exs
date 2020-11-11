defmodule SwaggerWrapperTest do
  use ExUnit.Case
  doctest SwaggerWrapper

  test "greets the world" do
    assert SwaggerWrapper.hello() == :world
  end
end
