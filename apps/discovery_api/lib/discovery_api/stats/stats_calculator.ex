defmodule DiscoveryApi.Stats.StatsCalculator do
  @moduledoc """
  Provides an interface for calculating statistics for all datasets in the Smart City Registry
  """
  require Logger
  alias DiscoveryApi.Stats.Completeness
  alias DiscoveryApi.Stats.CompletenessTotals
  alias DiscoveryApi.Data.Persistence
  alias DiscoveryApi.Data.Model

  @completeness_key "discovery-api:completeness_calculated_date"

  @doc """
  Entry point for calculating completeness statistics.  This method will get all datasets from the SmartCity Registry and calculate their completeness stats, saving them to redis.
  """
  def produce_completeness_stats do
    Persistence.persist("discovery-api:stats:start_time", DateTime.utc_now())

    Model.get_all()
    |> Enum.filter(&calculate_completeness?/1)
    |> Enum.each(&calculate_and_save_completeness/1)

    Persistence.persist("discovery-api:stats:end_time", DateTime.utc_now())
  end

  defp calculate_and_save_completeness(%Model{} = dataset) do
    dataset
    |> calculate_completeness_for_dataset()
    |> add_total_score()
    |> save_completeness()
  rescue
    e ->
      Logger.warn("#{inspect(e)}")
      :ok
  end

  # TODO: Add this check to the model?
  defp calculate_completeness?(%Model{} = dataset), do: dataset.sourceType != "remote" and inserted_since_last_calculation?(dataset)

  defp inserted_since_last_calculation?(%Model{} = dataset) do
    last_insert_date = Persistence.get("forklift:last_insert_date:#{dataset.id}")
    completion_calculated_date = Persistence.get("#{@completeness_key}:#{dataset.id}")
    last_insert_date > completion_calculated_date
  end

  defp calculate_completeness_for_dataset(%Model{} = dataset) do
    dataset
    |> get_dataset()
    |> Enum.reduce(%{}, fn x, acc -> Completeness.calculate_stats_for_row(dataset, x, acc) end)
    |> Map.put(:id, dataset.id)
  rescue
    _ -> %{id: dataset.id}
  end

  defp get_dataset(%Model{} = dataset) do
    get_statement = "select * from " <> dataset.systemName

    DiscoveryApi.prestige_opts()
    |> Prestige.new_session()
    |> Prestige.query!(get_statement)
    |> Prestige.Result.as_maps()
  end

  defp add_total_score(dataset_stats) do
    score = CompletenessTotals.calculate_dataset_total(dataset_stats)
    Map.put(dataset_stats, :total_score, score)
  end

  defp save_completeness(%{id: dataset_id, fields: fields} = dataset_stats) when not is_nil(fields) do
    Persistence.persist("discovery-api:stats:#{dataset_id}", dataset_stats)
    Persistence.persist("#{@completeness_key}:#{dataset_id}", DateTime.to_iso8601(DateTime.utc_now()))
    :ok
  end

  defp save_completeness(_dataset_stats), do: :ok
end
