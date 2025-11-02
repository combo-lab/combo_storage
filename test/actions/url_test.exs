defmodule WaffleTest.Actions.Url do
  use ExUnit.Case, async: false

  defmodule DummyStorage do
    use Waffle.Actions.Url
    use Waffle.Definition.Storage

    def __versions, do: [:original, :thumb, :skipped]
    def transform(:skipped, _), do: :skip
    def transform(_, _), do: :noaction
    def default_url(version, scope) when is_nil(scope), do: "dummy-#{version}"
    def default_url(version, scope), do: "dummy-#{version}-#{scope}"
    def __storage, do: Combo.Storage.Adapters.S3
  end

  test "delegates default_url generation to the definition when given a nil file" do
    assert DummyStorage.url(nil) == "dummy-original"
    assert DummyStorage.url(nil, :thumb) == "dummy-thumb"
    assert DummyStorage.url({nil, :scope}, :thumb) == "dummy-thumb-scope"
  end

  test "handles skipped versions" do
    assert DummyStorage.url("file.png", :skipped) == nil
  end
end
