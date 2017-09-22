defmodule WemoTest do
  use ExUnit.Case
  doctest Wemo

  test "greets the world" do
    assert Wemo.hello() == :world
  end
end
