defmodule DiscoveryApiWeb.DatasetPrestoQueryService do
  @moduledoc false

  def preview(dataset) do
    "select * from #{dataset} limit 50"
    |> Prestige.execute()
    |> Prestige.prefetch()
  end
end
