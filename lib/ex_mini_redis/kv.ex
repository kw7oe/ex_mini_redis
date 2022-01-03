defmodule ExMiniRedis.KV do
  @kv ExMiniRedis.KV.InMemory

  def start_link(opts) do
    @kv.start_link(opts)
  end

  def child_spec(opts) do
    @kv.child_spec(opts)
  end

  def get(key) do
    @kv.get(key)
  end

  def set(key, value) do
    @kv.set(key, value)
  end

  def delete(key) do
    @kv.delete(key)
  end
end

defmodule ExMiniRedis.KV.InMemory do
  use GenServer
  require Logger
  @table :key_dir

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> {:ok, value}
      _ -> {:error, :not_found}
    end
  end

  def set(key, value) do
    :ets.insert(@table, {key, value})
    :ok
  end

  def delete(key) do
    :ets.delete(@table, key)
    :ok
  end

  # GenServer callbacks
  @impl true
  def init(opts) do
    pid = :ets.new(@table, [:set, :named_table, :public, read_concurrency: true])
    Logger.info("Starting KV with ETS table #{pid}...")
    {:ok, opts}
  end
end

