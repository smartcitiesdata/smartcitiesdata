defmodule AndiWeb.EditLiveView.DataDictionaryTree do
  @moduledoc """
    LiveComponent for a nested data dictionary tree view
  """
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form

  alias AndiWeb.EditLiveView.DataDictionaryTree

  def mount(socket) do
    {:ok, assign(socket, expansion_map: %{})}
  end

  def render(assigns) do
    ~L"""
    <%= if is_set?(@form, @field) do %>
      <div id="<%= @id %>" class="data-dictionary-tree">
        <%= for field <- inputs_for(@form, @field) do %>
          <%= hidden_inputs(field, @selected_field_id) %> 
          <% {icon_modifier, selected_modifier} = get_action(field, assigns) %>
          <div class="data-dictionary-tree-field data-dictionary-tree__field data-dictionary-tree__field--<%= icon_modifier %> data-dictionary-tree__field--<%= selected_modifier %>">
            <div class="data-dictionary-tree-field__action" phx-click="<%= if is_set?(field, :subSchema), do: "toggle_expanded", else: "toggle_selected" %>" phx-value-field-id="<%= input_value(field, :id) %>" phx-target="#<%= @root_id %>"></div>
            <div class="data-dictionary-tree-field__text" phx-click="toggle_selected" phx-value-field-id="<%= input_value(field, :id) %>" phx-target="#<%= @root_id %>">
              <div class="data-dictionary-tree-field__name data-dictionary-tree-field-attribute"><%= input_value(field, :name) %></div>
              <div class="data-dictionary-tree-field__type data-dictionary-tree-field-attribute"><%= input_value(field, :type) %></div>
            </div>
          </div>
          <div class="data-dictionary-tree__sub-dictionary data-dictionary-tree__sub-dictionary--<%= icon_modifier %>">
            <%= live_component(@socket, DataDictionaryTree, id: :"#{@id}_#{input_value(field, :name)}", root_id: @root_id, selected_field_id: @selected_field_id, form: field, field: :subSchema, expansion_map: @expansion_map) %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  def handle_event("toggle_expanded", %{"field-id" => field_id}, %{assigns: %{expansion_map: expansion_map}} = socket) do
    updated_expansion_map = toggle_expansion(field_id, expansion_map)

    {:noreply, assign(socket, expansion_map: updated_expansion_map)}
  end

  def handle_event("toggle_selected", %{"field-id" => field_id}, socket) do
    {:noreply, assign(socket, selected_field_id: field_id)}
  end

  defp toggle_expansion(field_id, expansion_map) do
    toggled = not expanded?(field_id, expansion_map)

    Map.put(expansion_map, field_id, toggled)
  end

  defp expanded?(id, expansion_map) do
    Map.get(expansion_map, id, true)
  end

  defp get_action(field, assigns) do
    %{
      expansion_map: expansion_map,
      selected_field_id: selected_field_id
    } = assigns

    id = input_value(field, :id)

    icon_modifier =
      if is_set?(field, :subSchema) do
        if expanded?(id, expansion_map) do
          "expanded"
        else
          "collapsed"
        end
      else
        if id == selected_field_id do
          "checked"
        else
          "unchecked"
        end
      end

    selected_modifier =
      if id == selected_field_id do
        send(self(), {:assign_editable_dictionary_field, field})
        "selected"
      else
        "unselected"
      end

    {icon_modifier, selected_modifier}
  end

  defp is_set?(%{source: %{changes: changes}}, field), do: changes[field] != nil

  defp hidden_inputs(form_field, selected_field_id) do
    if input_value(form_field, :id) != selected_field_id do
      form_field.data
      |> Map.from_struct()
      |> Map.delete(:subSchema)
      |> Enum.map(fn {k, _v} ->
        hidden_input(form_field, k)
      end)
    end
  end
end