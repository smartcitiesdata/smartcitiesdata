defmodule DiscoveryApi.Data.TableInfoCache do
  @moduledoc """
  Simple module to cache systemName to dataset_id mapping
  """
  require Logger

  def child_spec([]) do
    Supervisor.child_spec({Cachex, cache_name()}, id: __MODULE__)
  end

  def put(data, id) do
    Cachex.put(cache_name(), id, data)
    data
  end

  def get(id) do
    Cachex.get!(cache_name(), id)
  end

  def invalidate() do
    Cachex.clear(cache_name())
  end

  defp cache_name() do
    :table_info
  end
end
