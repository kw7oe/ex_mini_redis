defmodule ExMiniRedis.Protocols.Server do
  @behaviour :ranch_protocol
  @timeout 5000

  def start_link(ref, transport, opts) do
    {:ok, spawn_link(__MODULE__, :init, [ref, transport, opts])}
  end

  def init(ref, transport, _opts) do
    {:ok, socket} = :ranch.handshake(ref)
    loop(socket, transport, "")
  end

  defp loop(socket, transport, state) do
    case transport.recv(socket, 0, @timeout) do
      {:ok, data} ->
        new_state = state <> data

        case ExMiniRedis.RESPParser.decode(new_state) do
          {:error, _} ->
            loop(socket, transport, new_state)

          {:ok, commands} ->
            handle_command(socket, transport, commands)
            loop(socket, transport, "")
        end

      _ ->
        transport.close(socket)
    end
  end

  defp handle_command(socket, transport, commands) do
    case commands do
      [_, "GET", "CONFIG"] ->
        transport.send(socket, "+OK\r\n")

      [_, "SET", "CONFIG"] ->
        transport.send(socket, "+OK\r\n")

      [value, key, "SET"] ->
        ExMiniRedis.KV.set(key, value)
        transport.send(socket, "+OK\r\n")

      [key, "GET"] ->
        case ExMiniRedis.KV.get(key) do
          {:ok, value} ->
            transport.send(socket, "+#{value}\r\n")

          {:error, :not_found} ->
            transport.send(socket, "+(nil)\r\n")
        end

      _ ->
        :ignore
    end
  end
end

defmodule ExMiniRedis.Listeners.Server do
  def child_spec(opts) do
    :ranch.child_spec(__MODULE__, :ranch_tcp, opts, ExMiniRedis.Protocols.Server, [])
  end
end

defmodule ExMiniRedis.ListenerSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl true
  def init({}) do
    children = [
      {ExMiniRedis.Listeners.Server, [{:port, 4000}]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
