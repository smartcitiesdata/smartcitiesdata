defmodule AndiWeb.EditLiveView.DataDictionaryAddFieldEditor do
  @moduledoc """
    LiveComponent for adding a field to a data dictionary
  """
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import AndiWeb.ErrorHelpers
  import Ecto.Query, only: [from: 2]

  alias Andi.InputSchemas.Options
  alias Andi.InputSchemas.StructTools
  alias Andi.InputSchemas.InputConverter
  alias Andi.InputSchemas.Datasets.DataDictionary
  alias Andi.InputSchemas.DataDictionaryFields

  def render(assigns) do
    id = Atom.to_string(assigns.id)

    modifier = if assigns.visible do
      "visible"
    else
      "invisible"
    end

    ~L"""
    <div id=<%= @id %> class="data-dictionary-add-field-editor data-dictionary-add-field-editor--<%= modifier %>">
    <%= form = form_for @changeset, "#", [phx_submit: "add_field", phx_target: "##{id}", as: :field] %>
        <div class="data-dictionary-add-field-editor__name">
          <%= label(form, :name, "Name", class: "label label--required") %>
          <%= text_input(form, :name, id: id <> "_name", class: "input") %>
          <%= error_tag(form, :name) %>
        </div>
        <div class="data-dictionary-add-field-editor__type">
          <%= label(form, :type, "Type", class: "label label--required") %>
          <%= select(form, :type, get_item_types(), id: id <> "_type", class: "select") %>
          <%= error_tag(form, :type) %>
        </div>
        <div class="data-dictionary-add-field-editor__parent-id">
          <%= label(form, :parent_id, "Child Of", class: "label") %>
          <%= select(form, :parent_id, @eligible_parents,  id: id <> "_child-of", class: "select") %>
        </div>
        <div>
          <button class="btn btn--large" phx-click="cancel">Cancel</button>
          <%= submit("Add Field", id: "add_field_button", class: "btn btn--large") %>
        </div>
       </form>
      </div>
    """
  end
  def mount(socket) do
    changeset = blank_changeset()
    {:ok, assign(socket, changeset: changeset, visible: false)}
  end

  def handle_event("cancel", _, socket) do
    send(self(), {:add_data_dictionary_field_cancelled})
    {:noreply, assign(socket, changeset: blank_changeset(), visible: false)}
  end

  def handle_event("add_field", %{"field" => %{"name" => name, "type" => type, "parent_id" => parent} = field}, socket) do
    field_as_atomic_map = AtomicMap.convert(field, safe: false)

    parent_bread_crumb = Enum.map(socket.assigns.eligible_parents, fn {n, i} ->
      {i, n}
    end)
    |> Map.new()
    |> Map.get(field_as_atomic_map.parent_id)

    new_changeset = case DataDictionaryFields.add_field_to_parent(field_as_atomic_map, parent_bread_crumb) do
      {:ok, field} ->
        send(self(), {:add_data_dictionary_field_succeeded, field.id})
        blank_changeset()
      {:error, changeset} ->
        Map.put(changeset, :action, :update)
    end

    {:noreply, assign(socket, changeset: new_changeset)}
  end

  defp blank_changeset() do
    DataDictionary.changeset(%DataDictionary{}, %{})
  end

  defp get_item_types(), do: map_to_dropdown_options(Options.items())
  defp get_item_types(field), do: map_to_dropdown_options(field, Options.items())

  defp map_to_dropdown_options(options) do
    Enum.map(options, fn {actual_value, description} -> [key: description, value: actual_value] end)
  end

  defp map_to_dropdown_options(field, options) do
    case input_value(field, :type) do
      "list" -> Enum.map(options, fn {actual_value, description} -> [key: description, value: actual_value] end)
      _ -> []
    end
  end
end