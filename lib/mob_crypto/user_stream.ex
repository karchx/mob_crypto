defmodule MobCrypto.UserStream do
  use WebSockex

  @pubsub MobCrypto.PubSub
  @topic "binance:market_data"
  @url "wss://stream.binance.com:9443/ws/dogeusdt@ticker"

  def start_link(_) do
    WebSockex.start_link(@url, __MODULE__, %{})
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    payload = Jason.decode!(msg)

    update_cache_ets(payload)

    Phoenix.PubSub.broadcast(@pubsub, @topic, {:binance_update, payload})

    {:ok, state}
  end

  def update_cache_ets(payload) do
    if payload["e"] == "24hrTicker" do
      :ets.insert(:binance_cache, {:balance, payload["c"]})
    end
  end
end
