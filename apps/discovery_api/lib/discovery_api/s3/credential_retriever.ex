defmodule DiscoveryApi.S3.CredentialRetriever do
  @moduledoc """
  Retrieves credentials for use in accessing restricted datasets.
  """
  use Properties, otp_app: :discovery_api

  require Logger

  getter(:secrets_endpoint, generic: true)

  def retrieve() do
    with {:ok, jwt} <- get_kubernetes_token(),
         {:ok, vault} <- instantiate_vault_conn(jwt),
         {:ok, credentials} <- Vault.read(vault, "secrets/smart_city/aws_keys/discovery_api") do
      Application.put_env(:ex_aws, :access_key_id, Map.get(credentials, "aws_access_key_id"))
      Application.put_env(:ex_aws, :secret_access_key, Map.get(credentials, "aws_secret_access_key"))
    else
      {:error, reason} ->
        error_message = "Unable to retrieve dataset credential; #{inspect(reason)}"
        Logger.error(error_message)
        raise error_message
    end
  end

  defp get_kubernetes_token() do
    case File.read("/var/run/secrets/kubernetes.io/serviceaccount/token") do
      {:error, :enoent} -> {:error, "Secret token file not found"}
      token -> token
    end
  end

  defp instantiate_vault_conn(token) do
    Vault.new(
      engine: Vault.Engine.KVV1,
      auth: Vault.Auth.Kubernetes,
      host: secrets_endpoint(),
      token_expires_at: set_login_ttl(20, :second)
    )
    |> Vault.auth(%{role: "discovery-api-role", jwt: token})
  end

  defp set_login_ttl(time, interval), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(time, interval)
end
