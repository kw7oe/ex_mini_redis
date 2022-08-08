defmodule ExMiniRedis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ExMiniRedis.Worker.start_link(arg)
      # {ExMiniRedis.Worker, arg}
      ExMiniRedis.KV,
      {ExMiniRedis.ListenerSupervisor, {}},
      {Task.Supervisor, name: ExMiniRedis.TaskSupervisor},
      {Task,
       fn -> ExMiniRedis.TcpServer.accept(String.to_integer(System.get_env("PORT") || "5000")) end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExMiniRedis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
