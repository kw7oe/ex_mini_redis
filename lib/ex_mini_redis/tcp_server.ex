defmodule ExMiniRedis.TcpServer do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, active: false, backlog: 50, packet: :line, reuseaddr: true])

    Logger.info("Accepting connection at port #{port}...")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(ExMiniRedis.TaskSupervisor, fn ->
        serve(client)
      end)

    Logger.info("Serving new client with pid: #{inspect(pid)}...")
    :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(client) do
    parse_command(client, "")
  end

  defp parse_command(client, state) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        new_state = state <> data

        case ExMiniRedis.RESPParser.decode(new_state) do
          {:error, _} ->
            parse_command(client, new_state)

          {:ok, commands} ->
            handle_command(client, commands)
            serve(client)
        end

      {:error, reason} ->
        if reason != :closed do
          {:error, :closed}
        else
          serve(client)
        end
    end
  end

  defp handle_command(client, commands) do
    case commands do
      [_, "GET", "CONFIG"] ->
        :gen_tcp.send(client, "+OK\r\n")

      [_, "SET", "CONFIG"] ->
        :gen_tcp.send(client, "+OK\r\n")

      [value, key, "SET"] ->
        ExMiniRedis.KV.set(key, value)
        :gen_tcp.send(client, "+OK\r\n")

      [key, "GET"] ->
        case ExMiniRedis.KV.get(key) do
          {:ok, value} ->
            :gen_tcp.send(client, "+#{value}\r\n")

          {:error, :not_found} ->
            :gen_tcp.send(client, "+(nil)\r\n")
        end

      _ ->
        :ignore
    end
  end
end
