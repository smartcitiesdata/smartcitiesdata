defmodule Forklift.Jobs.PartitionedCompactionTest do
  use ExUnit.Case
  alias SmartCity.TestDataGenerator, as: TDG
  alias Pipeline.Writer.TableWriter.Helper.PrestigeHelper
  alias Forklift.Jobs.PartitionedCompaction
  import SmartCity.TestHelper
  import Helper
  use Placebo

  @instance_name Forklift.instance_name()
  @batch_size 2

  import SmartCity.Event,
    only: [
      dataset_update: 0,
      data_ingest_start: 0
    ]

  setup do
    datasets =
      [1, 2]
      |> Enum.map(fn _ -> TDG.create_dataset(%{technical: %{cadence: "once"}}) end)
      |> Enum.map(fn dataset ->
        Brook.Event.send(@instance_name, dataset_update(), :forklift, dataset)
        Brook.Event.send(@instance_name, data_ingest_start(), :forklift, dataset)
        dataset
      end)

    wait_for_tables_to_be_created(datasets)
    delete_tables(datasets)
    recreate_tables_with_partitions(datasets)
    wait_for_tables_to_be_created(datasets)

    allow(Forklift.Quantum.Scheduler.deactivate_job(:data_migrator), return: :ok)
    allow(Forklift.Quantum.Scheduler.activate_job(:data_migrator), return: :ok)

    current_partition = Timex.format!(DateTime.utc_now(), "{YYYY}_{0M}")
    [datasets: datasets, current_partition: current_partition]
  end

  test "partitioned compaction runs without loss or error, ignoring invalid ids", %{
    datasets: datasets,
    current_partition: current_partition
  } do
    partitions = [current_partition]

    expected_record_count = write_test_data(datasets, partitions, @batch_size)

    dataset_ids = Enum.map(datasets, fn dataset -> dataset.id end)
    results = PartitionedCompaction.run(["invalid-id"] ++ dataset_ids)

    assert results == [:abort, :ok, :ok]
    assert Enum.all?(datasets, fn dataset -> count(dataset.technical.systemName) == expected_record_count end)

    refute Enum.any?(datasets, fn dataset ->
             table_exists?(PartitionedCompaction.compact_table_name(dataset.technical.systemName, current_partition))
           end)

    assert Enum.all?(datasets, fn dataset -> count_files(dataset.technical.systemName) == Enum.count(partitions) end)
  end

  test "abort compaction without loss if the compacted table for the partition exists at the start", %{
    datasets: datasets,
    current_partition: current_partition
  } do
    partitions = ["2018_01", current_partition]
    expected_record_count = write_test_data(datasets, partitions, @batch_size)

    error_dataset = List.first(datasets)

    error_dataset_compact_table =
      PartitionedCompaction.compact_table_name(error_dataset.technical.systemName, current_partition)

    "create table #{error_dataset_compact_table} as select 1 as number_col"
    |> PrestigeHelper.execute_query()

    dataset_ids = Enum.map(datasets, fn dataset -> dataset.id end)
    compaction_results = PartitionedCompaction.run(dataset_ids)

    assert compaction_results == [:error, :ok]
    assert table_exists?(error_dataset_compact_table)
    assert Enum.all?(datasets, fn dataset -> count(dataset.technical.systemName) == expected_record_count end)
  end

  test "abort compaction if the main table does not exist", %{datasets: datasets, current_partition: current_partition} do
    partitions = ["2018_01", current_partition]
    write_test_data(datasets, partitions, @batch_size)

    error_dataset = List.first(datasets)

    error_dataset_compact_table =
      PartitionedCompaction.compact_table_name(error_dataset.technical.systemName, current_partition)

    "drop table #{error_dataset.technical.systemName}"
    |> PrestigeHelper.execute_query()

    dataset_ids = Enum.map(datasets, fn dataset -> dataset.id end)
    compaction_results = PartitionedCompaction.run(dataset_ids)

    assert compaction_results == [:error, :ok]
    refute table_exists?(error_dataset_compact_table)
  end

  test "fail compaction without loss if the compacted table does not have the appropriate count", %{
    datasets: datasets,
    current_partition: current_partition
  } do
    error_dataset = List.first(datasets)

    error_dataset_compact_table =
      PartitionedCompaction.compact_table_name(error_dataset.technical.systemName, current_partition)

    allow(PrestigeHelper.count("#{error_dataset_compact_table}"),
      return: {:ok, 0},
      meck_options: [:passthrough]
    )

    partitions = ["2018_01", current_partition]
    expected_record_count = write_test_data(datasets, partitions, 2)

    dataset_ids = Enum.map(datasets, fn dataset -> dataset.id end)
    compaction_results = PartitionedCompaction.run(dataset_ids)

    assert compaction_results == [:error, :ok]
    assert Enum.all?(datasets, fn dataset -> count(dataset.technical.systemName) == expected_record_count end)
  end

  test "fail compaction, preserving the compacted table, if the final table does not have the appropriate count", %{
    datasets: datasets,
    current_partition: current_partition
  } do
    partitions = ["2018_01", current_partition]

    write_test_data(datasets, partitions, @batch_size)

    error_dataset = List.first(datasets)

    error_dataset_compact_table =
      PartitionedCompaction.compact_table_name(error_dataset.technical.systemName, current_partition)

    allow(
      PrestigeHelper.execute_query(
        "insert into #{error_dataset.technical.systemName} select * from #{error_dataset_compact_table}"
      ),
      return: {:ok, :false_positive},
      meck_options: [:passthrough]
    )

    dataset_ids = Enum.map(datasets, fn dataset -> dataset.id end)
    compaction_results = PartitionedCompaction.run(dataset_ids)

    assert compaction_results == [:error, :ok]

    assert PrestigeHelper.count!(error_dataset.technical.systemName) == @batch_size
    assert table_exists?(error_dataset_compact_table)
    assert PrestigeHelper.count!(error_dataset_compact_table) == @batch_size
  end

  test "abort compaction if no data for the current partition is found", %{datasets: datasets} do
    write_test_data(datasets, ["2018_01"], @batch_size)

    dataset_ids = Enum.map(datasets, fn dataset -> dataset.id end)
    compaction_results = PartitionedCompaction.run(dataset_ids)

    assert compaction_results == [:abort, :abort]
  end

  defp write_test_data(datasets, partitions, @batch_size) do
    datasets
    |> Enum.each(fn dataset ->
      Enum.each(partitions, fn partition ->
        write_partitioned_records(dataset, @batch_size, partition)
      end)
    end)

    Enum.count(partitions) * @batch_size
  end

  defp count_files(table) do
    [[count]] =
      "select count(distinct \"$path\") from #{table}" |> PrestigeHelper.execute_query() |> elem(1) |> Map.get(:rows)

    count
  end
end
