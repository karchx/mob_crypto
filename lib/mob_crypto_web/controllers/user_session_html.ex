defmodule MobCryptoWeb.UserSessionHTML do
  use MobCryptoWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:mob_crypto, MobCrypto.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
