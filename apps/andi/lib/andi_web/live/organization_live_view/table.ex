defmodule AndiWeb.OrganizationLiveView.Table do
  @moduledoc """
    LiveComponent for organization table
  """

  use Phoenix.LiveComponent
  import Phoenix.HTML
  alias Phoenix.HTML.Link

  def render(assigns) do
    ~L"""
    <div id="<%= @id %>" class="datasets-index__table">
      <table class="datasets-table">
      <thead>
        <th class="datasets-table__th datasets-table__cell datasets-table__th--sortable datasets-table__th--<%= Map.get(@order, "data_title", "unsorted") %>" phx-click="order-by" phx-value-field="data_title">Dataset Name </th>
        <th class="datasets-table__th datasets-table__cell datasets-table__th--sortable datasets-table__th--<%= Map.get(@order, "org_title", "unsorted") %>" phx-click="order-by" phx-value-field="org_title">Organization </th>
        <th class="datasets-table__th datasets-table__cell">Actions</th>
        </thead>

        <%= if @organizations == [] do %>
          <tr><td class="datasets-table__cell" colspan="100%">No Organizations Found!</td></tr>
        <% else %>
          <%= for org <- @organizations do %>
          <tr class="datasets-table__tr">
            <td class="datasets-table__cell datasets-table__cell--break datasets-table__ingested-cell"><%= ingest_status(org) %></td>
            <td class="datasets-table__cell datasets-table__cell--break"><%= org["data_title"] %></td>
            <td class="datasets-table__cell datasets-table__cell--break"><%= org["org_title"] %></td>
            <td class="datasets-table__cell datasets-table__cell--break"></td>
          </tr>
          <% end %>
        <% end %>
      </table>
    </div>
    """
  end

  defp ingest_status(org) do
    ""
  end
end
