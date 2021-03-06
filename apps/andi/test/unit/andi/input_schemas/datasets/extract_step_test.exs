defmodule Andi.InputSchemas.Datasets.ExtractStepTest do
  use ExUnit.Case
  # import Checkov

  alias Andi.InputSchemas.Datasets.ExtractStep

  test "fails for empty context" do
    changes = %{
      type: "http",
      context: nil
    }

    changeset = ExtractStep.changeset(changes)

    assert changeset.errors[:context] != nil
  end

  test "fails for invalid type" do
    changes = %{
      type: "blarg"
    }

    changeset = ExtractStep.changeset(changes)

    assert changeset.errors[:type] != nil
  end

  describe "context validation (http)" do
    test "required http step field" do
      changes = %{
        type: "http",
        context: %{
          url: ""
        }
      }

      changeset = ExtractStep.changeset(changes)

      assert changeset.errors[:url] != nil
      assert changeset.changes.context != nil
    end

    test "complexly validated http step field" do
      changes = %{
        type: "http",
        context: %{
          body: "this is not valid json"
        }
      }

      changeset = ExtractStep.changeset(changes)

      assert changeset.errors[:body] != nil
    end

    test "context is intact" do
      changes = %{
        type: "http",
        context: %{
          url: "www.example.com"
        }
      }

      changeset = ExtractStep.changeset(changes)

      assert changeset.errors[:url] == nil
      assert changeset.changes.context.url == "www.example.com"
    end
  end

  describe "context validation (date)" do
    test "required date step field" do
      changes = %{
        type: "date",
        context: %{
          format: ""
        }
      }

      changeset = ExtractStep.changeset(changes)

      assert changeset.errors[:format] != nil
      assert changeset.changes.context != nil
    end

    test "valid date step field" do
      changes = %{
        type: "date",
        context: %{
          deltaTimeValue: "bob"
        }
      }

      changeset = ExtractStep.changeset(changes)

      assert changeset.errors[:deltaTimeValue] != nil
      assert changeset.changes.context != nil
    end
  end
end
