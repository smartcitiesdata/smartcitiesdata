defmodule AndiWeb.EditLiveView.DataDictionaryForm do
  @moduledoc """
  LiveComponent for editing dataset schema
  """
  use Phoenix.LiveView
  import Phoenix.HTML.Form

  alias AndiWeb.EditLiveView.DataDictionaryTree
  alias AndiWeb.EditLiveView.DataDictionaryFieldEditor
  alias AndiWeb.InputSchemas.DataDictionaryFormSchema

  def mount(_, %{"dataset" => dataset}, socket) do
    new_changeset = DataDictionaryFormSchema.changeset_from_andi_dataset(dataset)
    {:ok, assign(socket,
        changeset: new_changeset,
        sourceFormat: dataset.technical.sourceFormat,
        visibility: "expanded",
        new_field_initial_render: false
      )
      |> assign(get_default_dictionary_field(new_changeset))}
  end

  def render(assigns) do
    action =
      case assigns.visibility do
        "collapsed" -> "EDIT"
        "expanded" -> "MINIMIZE"
      end

    ~L"""
    <div id="data-dictionary-form" class="form-component">
      <div class="component-header" phx-click="toggle-component-visibility" phx-value-component="data_dictionary_form">
        <h3 class="component-number component-number--<%= @visibility %>">2</h3>
        <div class="component-title full-width">
          <h2 class="component-title-text component-title-text--<%= @visibility %> ">Data Dictionary</h2>
          <div class="component-title-action">
            <div class="component-title-action-text--<%= @visibility %>"><%= action %></div>
            <div class="component-title-icon--<%= @visibility %>"></div>
          </div>
        </div>
      </div>

      <div class="form-section">
        <div class="component-edit-section--<%= @visibility %>">
          <div class="data-dictionary-form-edit-section form-grid">
            <div class="data-dictionary-form__tree-section">
              <div class="data-dictionary-form__tree-header data-dictionary-form-tree-header">
                <div class="label">Enter/Edit Fields</div>
                <div class="label label--inline">TYPE</div>
              </div>

              <div class="data-dictionary-form__tree-content data-dictionary-form-tree-content">
                <%= live_component(@socket, DataDictionaryTree, id: :data_dictionary_tree, root_id: :data_dictionary_tree, form: @changeset, field: :schema, selected_field_id: @selected_field_id, new_field_initial_render: @new_field_initial_render) %>
              </div>

              <div class="data-dictionary-form__tree-footer data-dictionary-form-tree-footer" >
                <div class="data-dictionary-form__add-field-button" phx-click="add_data_dictionary_field"></div>
                <div class="data-dictionary-form__remove-field-button" phx-click="remove_data_dictionary_field" phx-target="#dataset-edit-page"></div>
              </div>
            </div>

            <div class="data-dictionary-form__edit-section">
              <%= live_component(@socket, DataDictionaryFieldEditor, id: :data_dictionary_field_editor, form: @current_data_dictionary_item, source_format: @sourceFormat) %>
            </div>
          </div>

          <div class="edit-button-group form-grid">
            <div class="edit-button-group__cancel-btn">
              <a href="#metadata-form" id="back-button" class="btn btn--back btn--large" phx-click="toggle-component-visibility" phx-value-component-expand="metadata_form" phx-value-component-collapse="data_dictionary_form">Back</a>
              <button type="button" class="btn btn--large" phx-click="cancel-edit">Cancel</button>
            </div>

            <div class="edit-button-group__save-btn">
              <a href="#url-form" id="next-button" class="btn btn--next btn--large btn--action" phx-click="toggle-component-visibility" phx-value-component-expand="url_form" phx-value-component-collapse="data_dictionary_form">Next</a>
              <%= submit("Save Draft", id: "save-button", name: "save-button", class: "btn btn--save btn--large", phx_value_action: "draft") %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_default_dictionary_field(%{params: %{schema: schema}} = changeset) when schema != [] do
    first_data_dictionary_item =
      form_for(changeset, "#", as: :form_data)
      |> inputs_for(:schema)
      |> hd()

    first_selected_field_id = input_value(first_data_dictionary_item, :id)

    [
      current_data_dictionary_item: first_data_dictionary_item,
      selected_field_id: first_selected_field_id
    ]
  end

  defp get_default_dictionary_field(_changeset) do
    [
      current_data_dictionary_item: :no_dictionary,
      selected_field_id: :no_dictionary
    ]
  end
end
