defmodule DiscoveryApi.Application do
  @moduledoc """
  Discovery API serves as middleware between our metadata store and our Data Discovery UI.
  """
  use Application
  use Properties, otp_app: :discovery_api

  @instance_name DiscoveryApi.instance_name()

  getter(:brook, generic: true)
  getter(:secrets_endpoint, generic: true)
  getter(:elasticsearch, generic: true)

  def start(_type, _args) do
    import Supervisor.Spec

    get_s3_credentials()

    children =
      [
        {Phoenix.PubSub, [name: DiscoveryApi.PubSub, adapter: Phoenix.PubSub.PG2]},
        DiscoveryApi.Data.SystemNameCache,
        DiscoveryApiWeb.Plugs.ResponseCache,
        redis(),
        ecto_repo(),
        guardian_db_sweeper(),
        {Brook, brook()},
        cache_populator(),
        supervisor(DiscoveryApiWeb.Endpoint, []),
        DiscoveryApi.Quantum.Scheduler,
        DiscoveryApi.Data.TableInfoCache
      ]
      |> TelemetryEvent.config_init_server(@instance_name)
      |> List.flatten()

    opts = [strategy: :one_for_one, name: DiscoveryApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DiscoveryApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp redis do
    case Application.get_env(:redix, :args) do
      nil -> []
      redix_args -> {Redix, Keyword.put(redix_args, :name, :redix)}
    end
  end

  defp get_s3_credentials do
    secrets_endpoint()
    |> case do
      nil -> nil
      _ -> DiscoveryApi.S3.CredentialRetriever.retrieve()
    end
  end

  defp ecto_repo do
    Application.get_env(:discovery_api, DiscoveryApi.Repo)
    |> case do
      nil -> []
      _ -> [{DiscoveryApi.Repo, []}, DiscoveryApi.Data.VisualizationMigrator]
    end
  end

  defp guardian_db_sweeper do
    Application.get_env(:discovery_api, Guardian.DB)
    |> case do
      nil ->
        []

      config ->
        Application.put_env(:guardian, Guardian.DB, config)
        Supervisor.Spec.worker(Guardian.DB.Token.SweeperServer, [])
    end
  end

  defp cache_populator do
    elasticsearch()
    |> case do
      nil -> []
      _ -> DiscoveryApi.Data.CachePopulator
    end
  end
end
