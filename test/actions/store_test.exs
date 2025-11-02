defmodule WaffleTest.Actions.Store do
  use ExUnit.Case, async: false

  defmodule DummyStorage do
    use Waffle.Actions.Store
    use Waffle.Definition.Storage

    def validate({file, _}),
      do: String.ends_with?(file.file_name, ".png") || String.ends_with?(file.file_name, ".ico")

    def transform(:skipped, _), do: :skip
    def transform(_, _), do: :noaction
    def __versions, do: [:original, :thumb, :skipped]
  end

  defmodule DummyStorageWithExtension do
    use Waffle.Actions.Store
    use Waffle.Definition.Storage

    def validate({file, _}), do: String.ends_with?(file.file_name, ".png")

    def transform(:convert_to_jpg, _),
      do: {:convert, "-format jpg", :jpg}

    def transform(:custom_to_jpg, {file, _}) do
      {
        fn _, _ -> {:ok, file} end,
        fn _, _ -> :jpg end
      }
    end

    def __versions, do: [:convert_to_jpg, :custom_to_jpg]
  end

  defmodule DummyStorageWithHeaders do
    use Waffle.Actions.Store
    use Waffle.Definition.Storage

    def transform(_, _), do: :noaction
    def __versions, do: [:original, :thumb, :skipped]
    def remote_file_headers(%URI{host: "www.google.com"}), do: [{"User-Agent", "MyApp"}]
  end

  defmodule DummyStorageWithValidationError do
    use Waffle.Actions.Store
    use Waffle.Definition.Storage

    def validate(_), do: {:error, "invalid file type"}
    def transform(_, _), do: :noaction
    def __versions, do: [:original, :thumb, :skipped]
  end

  test "checks file existence" do
    assert DummyStorage.store("non-existent-file.png") == {:error, :invalid_file_path}
  end

  test "delegates to definition validation" do
    assert DummyStorage.store(__ENV__.file) == {:error, :invalid_file}
  end

  test "supports custom validation error message" do
    assert DummyStorageWithValidationError.store(__ENV__.file) == {:error, "invalid file type"}
  end
end
