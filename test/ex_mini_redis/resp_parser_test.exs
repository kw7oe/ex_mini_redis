defmodule ExMiniRedis.RESPParserTest do
  use ExUnit.Case, async: true

  test "GET is encoded correctly" do
    input = "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n"

    correct_input =
      ["GET", "key"]
      # By default, Redix.Protocol.pack return iodata
      # so it can be send with gen_tcp.send/2. So, we need
      # to convert it to binary using IO.iodata_to_binary/1.
      #
      # If you're viewing this on Livebook, just hover over the
      # `pack` word and you'll see the documentation.
      |> Redix.Protocol.pack()
      |> IO.iodata_to_binary()

    assert input == correct_input
  end

  test "SET is encoded correctly" do
    input = "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n"

    correct_input =
      ["SET", "key", "value"]
      |> Redix.Protocol.pack()
      |> IO.iodata_to_binary()

    assert input == correct_input
  end

  test "Decoding partial input" do
    input = "*2\r\n"
    assert {:error, :incomplete_command} = ExMiniRedis.RESPParser.decode(input)

    input = "*2\r\n$3\r\nGET\r\n"
    assert {:error, :incomplete_command} = ExMiniRedis.RESPParser.decode(input)

    input = "*2\r\n$3\r\nGET\r\n$3\r\n"
    assert {:error, :incomplete_command} = ExMiniRedis.RESPParser.decode(input)

    input = "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n"
    assert {:ok, ["GET", "key"]} = ExMiniRedis.RESPParser.decode(input)

    input =  "*3\r\n$6\r\nCONFIG\r\n$3\r\nGET\r\n$4\r\nsave\r\n"
    assert {:ok, ["CONFIG", "GET", "save"]} = ExMiniRedis.RESPParser.decode(input)
  end
end
