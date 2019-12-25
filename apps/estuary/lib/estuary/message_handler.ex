defmodule Estuary.MessageHandler do
  @moduledoc """
  Estuary.MessageHandler reads an event from the event stream and persists it.
  """

  # SC - Starts
  alias Estuary.Util
  import Estuary
  alias Estuary.Datasets.DatasetSchema
  # import SmartCity.Data, only: [end_of_data: 0]

  @reader Application.get_env(:estuary, :topic_reader)

  def handle_messages(messages) do
    messages
    |> parse_message_value()

    # |> Enum.map(&parse_message_value/1)
    # |> Enum.map(&yeet_error/1)
  end

  defp parse_message_value(message) do
    message
    |> IO.inspect("Hellooooo")
    |> Jason.decode()
    |> process_message()
  end

  defp process_message(
         {:ok, %{"author" => _, "create_ts" => _, "data" => _, "type" => _} = event}
       ) do
    # init_args <- reader_args(event)
    # reader_args(event)
    # :ok = @reader.init(init_args)

    event
    |> DatasetSchema.make_datawriter_payload()
    |> DataWriter.write()
  end

  defp process_message({_, term}) do
    :discard
  end

  # defp parse(end_of_data() = message), do: message

  defp parse(%{key: key, value: value} = message) do
    case SmartCity.Data.new(value) do
      {:ok, datum} -> Util.add_to_metadata(datum, :kafka_key, key)
      {:error, reason} -> {:error, reason, message}
    end
  end

  defp yeet_error({:error, reason, message} = error_tuple) do
    Estuary.DeadLetterQueue.enqueue(message, reason: reason)
    error_tuple
  end

  defp parse(%{key: key, value: value} = message) do
    case SmartCity.Data.new(value) do
      {:ok, datum} -> Util.add_to_metadata(datum, :kafka_key, key)
      {:error, reason} -> {:error, reason, message}
    end
  end

  defp yeet_error(valid), do: valid

  defp error_tuple?({:error, _, _}), do: true
  defp error_tuple?(_), do: false

  # SC - Ends

  # alias Estuary.EventTable
  # use Elsa.Consumer.MessageHandler
  # require Logger

  # def handle_messages(messages) do
  #   Enum.each(messages, fn message -> process_message(message) end)

  #   Logger.debug("Messages #{inspect(messages)} were sent to the event stream")
  #   :ack
  # end

  # defp process_message(message) do
  #   case Jason.decode(message.value) do
  #     {:ok, %{"author" => _, "create_ts" => _, "data" => _, "type" => _} = event} ->
  #       do_insert(message, event)

  #     {_, term} ->
  #       process_error(message, term)
  #   end
  # end

  # defp do_insert(_message, event) do
  #   case EventTable.insert_event_to_table(event) do
  #     {:error, message} ->
  #       process_error(message, event)

  #     term ->
  #       term
  #   end
  # end

  # defp process_error(message, data) do
  #   Yeet.process_dead_letter("", message, "estuary",
  #     reason: "could not process because #{inspect(data)}"
  #   )
  # end
end
