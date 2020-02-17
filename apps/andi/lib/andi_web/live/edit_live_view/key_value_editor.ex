defmodule AndiWeb.EditLiveView.KeyValueEditor do
  @moduledoc """
    LiveComponent for an nested key/value form
  """
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import AndiWeb.ErrorHelpers

  alias Andi.InputSchemas.DisplayNames

  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="url-form__<%= @css_label %> url-form-table">
      <div class="url-form-table__title"><%= DisplayNames.get(@field) %></div>
      <table class="url-form-table__table">
      <tr class="url-form-table__row url-form-table__row--bordered">
        <th class="url-form-table__cell url-form-table__cell--bordered url-form-table__cell--header">KEY</th>
        <th class="url-form-table__cell url-form-table__cell--bordered url-form-table__cell--header" colspan="2" >VALUE</th>
      </tr>
      <%= if has_values(input_value(@form, @field)) do %>
        <%= inputs_for @form, @field, fn f -> %>
        <tr class="url-form-table__row url-form-table__row--bordered">
          <td class="url-form-table__cell url-form-table__cell--bordered">
            <%= text_input(f, :key, class: "input full-width url-form__#{@css_label}-key-input #{input_value(f, :id)}") %>
          </td>
          <td class="url-form-table__cell url-form-table__cell--bordered">
            <%= text_input(f, :value, class: "input full-width url-form__#{@css_label}-value-input #{input_value(f, :id)}") %>
          </td>
          <td class="url-form-table__cell url-form-table__cell--delete">
            <img src="/images/remove.svg" alt="Remove" class="url-form__<%= @css_label %>-delete-btn url-form-table__btn" phx-click="remove" phx-value-id="<%= input_value(f, :id) %>" phx-value-field="<%= @field %>" />
          </td>
        </tr>
        <% end %>
      <% end %>
      </table>
      <img src="/images/add.svg" alt="Add" class="url-form__<%= @css_label %>-add-btn url-form-table__btn" phx-click="add" phx-value-field="<%= @field %>"/>
      <%= error_tag_live(@form, @field) %>
    </div>
    """
  end

  def handle_event("add", payload, socket) do
    send(self(), {:add_key_value, payload})
    {:noreply, socket}
  end

  def handle_event("remove", payload, socket) do
    send(self(), {:remove_key_value, payload})
    {:noreply, socket}
  end

  def handle_event("validate", payload, socket) do
    send(self(), {:validate, payload})
    {:noreply, socket}
  end

  #TODO: why is this still blowing up sometimes saying that the key is not in the changeset?  These guards should be defending against this
  defp has_values(nil), do: false
  defp has_values(%{}), do: false
  defp has_values([]), do: false
  defp has_values(_), do: true
end
