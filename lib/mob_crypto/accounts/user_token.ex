defmodule MobCrypto.Accounts.UserToken do

  import Ecto.Query, warn: false
  alias MobCrypto.Repo

  alias MobCrypto.Accounts.User

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the magic link token expiry short,
  # since someone with access to the email may take over the account.
  @magic_link_validity_in_minutes 15
  @change_email_validity_in_days 7
  @session_validity_in_days 14

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.
  """
  def build_session_token(user) do
    ttl = 86_400 * 7
    {public_token, hashed_token} = generate_token_pair()

    dt = user.authenticated_at || DateTime.utc_now(:second)
    expire_ts = dt |> DateTime.add(ttl, :second) |> DateTime.to_unix()

    save_session_to_redis!(user.id, hashed_token, ttl, dt, expire_ts)

    public_token
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  def build_email_token(user, context) do
    {public_token, hashed_token} = generate_token_pair()

    ttl = 900 # 15 minutes
    save_email_token_to_redis!(user.email, context, hashed_token, ttl)

    public_token
  end


  defp generate_token_pair do
    raw_token = :crypto.strong_rand_bytes(@rand_size)

    public_token = Base.url_encode64(raw_token, padding: false)
    hashed_token =
      :crypto.hash(@hash_algorithm, raw_token)
      |> Base.url_encode64(padding: false)

    {public_token, hashed_token}
  end

  defp save_session_to_redis!(user_id, hashed_token, ttl, dt, expire_ts) do
    dt_string = DateTime.to_iso8601(dt)
    user_id_str = to_string(user_id)

    {:ok, _} = Redix.pipeline(:redix, [
      ["SETEX", "session:#{hashed_token}", to_string(ttl), user_id_str],
      ["ZADD", "user:#{user_id}:sessions:dt_#{dt_string}", to_string(expire_ts), hashed_token]
    ])

    :ok
  end

  defp save_email_token_to_redis!(email, context, hashed_token, ttl) do
    key = "email_token:#{context}:#{hashed_token}"

    {:ok, _} = Redix.command(:redix, ["SETEX", key, to_string(ttl), email])

    :ok
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  If found, the query returns a tuple of the form `{user, token}`.

  The given token is valid if it matches its hashed counterpart in the
  database. This function also checks whether the token has expired. The context
  of a magic link token is always "login".
  """
  def verify_magic_link_token(token, context \\ "login") do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = 
          :crypto.hash(@hash_algorithm, decoded_token)
          |> Base.url_encode64(padding: false)

        key = "email_token:#{context}:#{hashed_token}"

        case Redix.command(:redix, ["GETDEL", key]) do
          {:ok, email} when is_binary(email) ->
            case Repo.get_by(User, email: email) do
              nil -> :error
              user -> {:ok, user}
            end

          {:ok, nil} ->
            :error

          {:error, _reason} ->
            :error
        end

      :error ->
        :error
    end
  end


  def verify_change_email_token(token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token) |> Base.url_encode64(padding: false)
        key = "email_token:#{context}:#{hashed_token}"

        case Redix.command(:redix, ["GETDEL", key]) do
          {:ok, email} when is_binary(email) ->
            {:ok, email}
          _ ->
            :error
        end

      :error ->
        :error
    end
  end
end
