defmodule ExMiniRedisTest do
  use ExUnit.Case
  doctest ExMiniRedis

  test "greets the world" do
    assert ExMiniRedis.hello() == :world
  end
end
