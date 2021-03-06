defmodule AndiWeb.InputSchemas.DatasetLinkFormSchema do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "dataset_link" do
    field(:datasetLink, :string)
  end

  use Accessible

  @cast_fields [
    :datasetLink
  ]

  @required_fields [
    :datasetLink
  ]

  def changeset(changes), do: changeset(%__MODULE__{}, changes)

  def changeset(dataset_link, changes) do
    dataset_link
    |> cast(changes, @cast_fields)
    |> validate_required(@required_fields, message: "is required")
  end

  def changeset_for_draft(dataset_link, changes) do
    cast(dataset_link, changes, @cast_fields)
  end

  def changeset_from_andi_dataset(dataset) do
    changeset(%{datasetLink: dataset.datasetLink})
  end

  def changeset_from_form_data(form_data) do
    form_data
    |> AtomicMap.convert(safe: false, underscore: false)
    |> changeset()
  end
end
