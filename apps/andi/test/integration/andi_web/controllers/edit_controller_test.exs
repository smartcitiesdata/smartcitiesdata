defmodule AndiWeb.EditControllerTest do
  use ExUnit.Case
  use Andi.DataCase
  use AndiWeb.Test.AuthConnCase.IntegrationCase

  @moduletag shared_data_connection: true

  alias Andi.InputSchemas.Datasets
  alias SmartCity.TestDataGenerator, as: TDG

  @url_path "/datasets"

  describe "EditController" do
    test "gives 404 if dataset is not found", %{conn: conn} do
      conn = get(conn, "#{@url_path}/#{UUID.uuid4()}")

      assert response(conn, 404)
    end

    test "gives 200 if dataset is found", %{conn: conn} do
      smrt_dataset = TDG.create_dataset(%{})
      {:ok, dataset} = Datasets.update(smrt_dataset)

      conn = get(conn, "#{@url_path}/#{dataset.id}")
      assert response(conn, 200)
    end
  end

  describe "download dataset sample" do
    setup do
      smrt_dataset = TDG.create_dataset(%{})
      {:ok, andi_dataset} = Datasets.update(smrt_dataset)

      [andi_dataset: andi_dataset]
    end

    test "redirects users with a curator role", %{curator_conn: curator_conn, andi_dataset: andi_dataset} do
      dataset_link = "#{andi_dataset.id}/cam.csv"

      changes_with_dataset_link =
        andi_dataset
        |> Map.put(:datasetLink, dataset_link)
        |> AtomicMap.convert(underscore: false)

      {:ok, andi_dataset} = Datasets.update(andi_dataset, changes_with_dataset_link)

      conn = get(curator_conn, "#{@url_path}/#{andi_dataset.id}/sample")

      assert response(conn, 302)
      assert redirected_to(conn) =~ dataset_link
    end

    test "displays error for users without a curator role", %{public_conn: public_conn, andi_dataset: andi_dataset} do
      conn = get(public_conn, "#{@url_path}/#{andi_dataset.id}/sample")
      assert response(conn, 302)
      assert redirected_to(conn) == "/auth/auth0?prompt=login&error_message=Unauthorized"
    end

    test "returns 404 when there is no dataset link associated with the dataset", %{
      curator_conn: curator_conn,
      andi_dataset: andi_dataset
    } do
      conn = get(curator_conn, "#{@url_path}/#{andi_dataset.id}/sample")
      assert response(conn, 404)
    end

    test "persists download requests to postgres for successful downloads", %{curator_conn: curator_conn, andi_dataset: andi_dataset} do
      dataset_link = "#{andi_dataset.id}/cam.csv"

      changes_with_dataset_link =
        andi_dataset
        |> Map.put(:datasetLink, dataset_link)
        |> AtomicMap.convert(underscore: false)

      {:ok, andi_dataset} = Datasets.update(andi_dataset, changes_with_dataset_link)

      conn = get(curator_conn, "#{@url_path}/#{andi_dataset.id}/sample")

      download_log = Andi.Repo.get_by(Andi.Schemas.DatasetDownload, dataset_id: andi_dataset.id)

      assert download_log != nil

      associated_user = Andi.Repo.get(Andi.Schemas.User, download_log.user_accessing)

      assert download_log.dataset_id == andi_dataset.id
      assert download_log.dataset_link == dataset_link
      assert associated_user.email == "bob@example.com"
      assert download_log.download_success
    end

    test "persists download requests to postgres for unsuccessful downloads", %{curator_conn: curator_conn, andi_dataset: andi_dataset} do
      conn = get(curator_conn, "#{@url_path}/#{andi_dataset.id}/sample")

      download_log = Andi.Repo.get_by(Andi.Schemas.DatasetDownload, dataset_id: andi_dataset.id)

      assert download_log != nil

      associated_user = Andi.Repo.get(Andi.Schemas.User, download_log.user_accessing)

      assert download_log.dataset_id == andi_dataset.id
      assert download_log.dataset_link == nil
      assert associated_user.email == "bob@example.com"
      refute download_log.download_success
    end
  end
end
