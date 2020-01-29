defmodule Estuary.Query.Select do
  @moduledoc false

  def select_table(value) do
    data =
      Application.get_env(:prestige, :session_opts)
      |> Prestige.new_session()
      |> Prestige.query!(create_query_statement(value))
      |> Prestige.Result.as_maps()

    {:ok, data}
  rescue
    error -> {:error, error}
  end

  defp create_query_statement(value) do
    "SELECT #{translate_columns(value["columns"])}
      FROM #{check_table_name(value["table_name"])}
      #{translate_order(value["order_by"], value["order"])}
      LIMIT #{translate_limit(value["limit"])}"
  end

  defp translate_columns(columns) do
    case !is_nil(columns) do
      true ->
        columns
        |> Enum.reject(&(byte_size(&1) == 0))
        |> Enum.map_join(", ", & &1)

      _ ->
        "*"
    end
  end

  defp check_table_name(table_name) do
    case !is_nil(table_name) and byte_size(table_name) != 0 do
      true -> table_name
      _ -> raise "Table name missing"
    end
  end

  defp translate_order(order_by, order) do
    if !is_nil(order_by) and byte_size(order_by) != 0 do
      "ORDER BY #{order_by} #{translate_order(order)}"
    end
  end

  defp translate_order(order) do
    case order == "DESC" do
      true -> "DESC"
      _ -> "ASC"
    end
  end

  defp translate_limit(limit) do
    case is_integer(limit) do
      true -> limit
      _ -> "ALL"
    end
  end
end
