defmodule WaffleTest.Actions.Url do
  use ExUnit.Case, async: false

  defmodule DummyStorage do
    use Waffle.Actions.Url
    use Waffle.Definition.Storage

    def __versions, do: [:original, :thumb, :skipped]
    def transform(:skipped, _), do: :skip
    def transform(_, _), do: :noaction
    def __storage, do: Combo.Storage.Adapters.S3
  end

  test "handles skipped versions" do
    assert DummyStorage.url("file.png", :skipped) == nil
  end
end
