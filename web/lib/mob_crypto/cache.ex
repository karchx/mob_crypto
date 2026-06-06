defmodule MobCrypto.Cache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    :ets.new(:binance_cache, [:set, :named_table, :public, read_concurrency: true])
    {:ok, %{}}
  end
end
