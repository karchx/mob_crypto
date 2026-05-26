defmodule MobCrypto.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    redis_url = System.get_env("REDIS_URL") || "redis://localhost:6379"

    children = [
      MobCryptoWeb.Telemetry,
      MobCrypto.Repo,
      {Redix, name: :redix, sync_connect: true},
      {DNSCluster, query: Application.get_env(:mob_crypto, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MobCrypto.PubSub},
      # Start a worker by calling: MobCrypto.Worker.start_link(arg)
      # {MobCrypto.Worker, arg},
      # Start to serve requests, typically the last entry
      MobCryptoWeb.Endpoint,
      MobCrypto.Cache,
      MobCrypto.UserStream
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MobCrypto.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MobCryptoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
