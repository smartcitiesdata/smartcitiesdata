defmodule Auth.Auth0.CachedJWKS do
  @moduledoc """
  """
  use Memoize

  defmemo get_key(issuer, key_id) do
    IO.inspect(key_id, label: "were looking for tihs")
    keystore =
      case HTTPoison.get(issuer <> ".well-known/jwks.json") do
        {:ok, %{body: body}} -> Jason.decode(body)
        error -> error
      end

    key_from_jwks(keystore, key_id)
  end

  defp key_from_jwks({:error, _reason} = error, _key_id), do: error

  defp key_from_jwks({:ok, jwks}, key_id) do
    key =
      jwks
      |> Map.get("keys")
      |> Enum.find(fn key -> Map.get(key, "kid") == key_id end)

    case key do
      nil -> {:error, "no key for kid: #{key_id}"}
      key -> {:ok, JOSE.JWK.from(key)}
    end
  end

  def clear() do
    Memoize.invalidate(__MODULE__)
  end
end
