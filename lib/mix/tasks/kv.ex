defmodule Mix.Tasks.Benchmark.Kv do
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")
    ExMiniRedis.KV.set("KSDI101", "default")

    Benchee.run(
      %{
        "set" => fn ->
          ExMiniRedis.KV.set("KSDI101", "valuevalue")
        end,
        "get" => fn ->
          ExMiniRedis.KV.get("KSDI101")
        end
      },
      time: 10,
      memory_time: 2
    )
  end
end
