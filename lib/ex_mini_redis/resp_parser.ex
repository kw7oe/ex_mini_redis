defmodule ExMiniRedis.RESPParser do
  def encode(commands) when is_list(commands) do
    result = "*#{length(commands)}\r\n"

    Enum.reduce(commands, result, fn command, result ->
      result <> "$#{String.length(command)}\r\n#{command}\r\n"
    end)
  end

  def decode(string) when is_binary(string) do
    %{commands: commands} =
      string
      |> String.trim()
      |> String.split("\r\n")
      |> Enum.reduce(%{}, fn reply, state ->
        case reply do
          "*" <> length ->
            state
            |> Map.put(:type, "array")
            |> Map.put(:array_length, String.to_integer(length))

          "$" <> length ->
            state
            |> Map.put(:type, "bulk_string")
            |> Map.put(:bulk_string_length, String.to_integer(length))

          value ->
            value = String.trim(value)
            Map.update(state, :commands, [value], fn list -> [value | list] end)
        end
      end)

    Enum.reverse(commands)
  end
end
