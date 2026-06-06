defmodule MobCrypto.Repo do
  use Ecto.Repo,
    otp_app: :mob_crypto,
    adapter: Ecto.Adapters.Postgres
end
