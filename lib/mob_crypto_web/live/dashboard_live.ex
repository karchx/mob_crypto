defmodule MobCryptoWeb.DashboardLive do
  use MobCryptoWeb, :live_view

  @topic "binance:market_data"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MobCrypto.PubSub, @topic)
    end

    init_balance =
      case :ets.lookup(:binance_cache, :balances) do
        [{:balances, data}] -> data
        [] -> "Loading..."
      end

    {:ok, assign(socket, balances: init_balance)}
  end

  @impl true
  def handle_info({:binance_update, %{"e" => "24hrTicker", "c" => price}}, socket) do
    {:noreply, assign(socket, balances: price)}
  end

  # Fallback
  def handle_info(_, socket), do: {:noreply, socket}
end
