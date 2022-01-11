defmodule ExMiniRedis.RESPParserTest do
  use ExUnit.Case, async: true

  test "encode and decode" do
    reply = "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n"
    assert {:ok, ["key", "GET"]} = ExMiniRedis.RESPParser.decode(reply)

    list = ["GET", "key"]
    assert "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n" = ExMiniRedis.RESPParser.encode(list)
  end

  test "Decoding partial input" do
    input = "*2\r\n"
    assert {:error, :incomplete_command} = ExMiniRedis.RESPParser.decode(input)

    input = "*2\r\n$3\r\nGET\r\n"
    assert {:error, :incomplete_command} = ExMiniRedis.RESPParser.decode(input)

    input = "*2\r\n$3\r\nGET\r\n$3\r\n"
    assert {:error, :incomplete_command} = ExMiniRedis.RESPParser.decode(input)

    input = "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n"
    assert {:ok, ["key", "GET"]} = ExMiniRedis.RESPParser.decode(input)

    input =  "*3\r\n$6\r\nCONFIG\r\n$3\r\nGET\r\n$4\r\nsave\r\n"
    assert {:ok, ["save", "GET", "CONFIG"]} = ExMiniRedis.RESPParser.decode(input)
  end
end
