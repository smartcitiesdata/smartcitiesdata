Divo.Suite.start()
# Wait for Brook to be ready
Process.sleep(5_000)
ExUnit.start(exclude: [:performance, :compaction, :skip], timeout: 120_000)
Faker.start()

defmodule Helper do
  use Properties, otp_app: :forklift

  import SmartCity.TestHelper
  alias SmartCity.TestDataGenerator, as: TDG
  alias Pipeline.Writer.TableWriter.Helper.PrestigeHelper
  alias Pipeline.Writer.TableWriter.Statement
  alias Pipeline.Writer.S3Writer
  require ExUnit.Assertions

  getter(:s3_writer_bucket, generic: true)

  def make_kafka_message(value, topic) do
    %{
      topic: topic,
      value: value |> Jason.encode!(),
      offset: :rand.uniform(999)
    }
  end

  def table_exists?(table) do
    case PrestigeHelper.execute_query("show create table #{table}") do
      {:ok, _} -> true
      _ -> false
    end
  end

  def drop_table(table) do
    %{table: table}
    |> Statement.drop()
    |> PrestigeHelper.execute_query()
  end

  def create_partitioned_table(table) do
    "create table #{table} with (partitioned_by = ARRAY['os_partition'], format = 'ORC') as (select *, cast('2020-09' as varchar) as os_partition from #{
      table
    }__json) limit 0"
    |> PrestigeHelper.execute_query()
  end

  def write_records(dataset, count) do
    data = 1..count |> Enum.map(fn _ -> TDG.create_data(%{payload: payload()}) end)

    S3Writer.write(data,
      bucket: s3_writer_bucket(),
      table: dataset.technical.systemName,
      schema: dataset.technical.schema
    )
  end

  def write_partitioned_records(dataset, count, partition) do
    1..count |> Enum.map(fn _ -> insert_record(dataset.technical.systemName, partition) end)
  end

  defp insert_record(table, partition) do
    "insert into #{table} values (1, 'Bob', cast(now() as date), 1.5, true, '#{partition}')"
    |> PrestigeHelper.execute_query()
  end

  def payload() do
    %{
      "my_int" => 1,
      "my_string" => "Bob",
      "my_date" => Timex.format!(DateTime.utc_now(), "{ISO:Extended:Z}"),
      "my_float" => 1.5,
      "my_boolean" => "true"
    }
  end

  def count(table) do
    case PrestigeHelper.execute_query("select count(1) from #{table}") do
      {:ok, new_results} ->
        [[new_row_count]] = new_results.rows
        new_row_count

      _ ->
        :error
    end
  end

  def wait_for_tables_to_be_created(datasets) do
    eventually(
      fn ->
        ExUnit.Assertions.assert(Enum.all?(datasets, fn dataset -> table_exists?(dataset.technical.systemName) end))
      end,
      100,
      1_000
    )
  end

  def delete_tables(datasets) do
    Enum.each(datasets, fn dataset -> drop_table(dataset.technical.systemName) end)
  end

  def recreate_tables_with_partitions(datasets) do
    Enum.each(datasets, fn dataset -> create_partitioned_table(dataset.technical.systemName) end)
  end
end
