defmodule MobCrypto.Rest do
  @base_url "https://api.binance.com"

  def get_listen_key do
    api_key = System.get_env("BINANCE_API_KEY", "xxx")

    url = "#{@base_url}/api/v3/userDataStream"
    headers = [
      {"X-MBX-APIKEY", api_key},
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"User-Agent", "MobCrypto/0.1.0"}
    ]

    case Req.post!(url, headers: headers, body: "") do
      %{status: 200, body: %{"listenKey" => key}} ->
        key
      error ->
        raise "Error get listenKey: #{inspect(error)}"
    end
  end

  def sign_payload(payload) do
    :crypto.mac(:hmac, :sha256, api_secret(), payload) |> Base.encode16(case: :lower)
  end

  def api_secret, do: System.get_env("BINANCE_API_SECRET", "xxx")
end
