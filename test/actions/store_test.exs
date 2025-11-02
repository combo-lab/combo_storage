defmodule WaffleTest.Actions.Store do
  use ExUnit.Case, async: false

  @img "test/support/image.png"

  import Mock

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

  test "custom transformations change a file extension" do
    with_mock Combo.Storage.Adapters.S3,
      put: fn DummyStorageWithExtension, _, {%{file_name: "image.jpg", path: _}, nil} ->
        {:ok, "resp"}
      end do
      assert DummyStorageWithExtension.store(@img) == {:ok, "image.png"}
    end
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

  test "single binary argument is interpreted as file path" do
    with_mock Combo.Storage.Adapters.S3,
      put: fn DummyStorage, _, {%{file_name: "image.png", path: @img}, nil} ->
        {:ok, "resp"}
      end do
      assert DummyStorage.store(@img) == {:ok, "image.png"}
    end
  end

  test "two-tuple argument interpreted as path and scope" do
    with_mock Combo.Storage.Adapters.S3,
      put: fn DummyStorage, _, {%{file_name: "image.png", path: @img}, :scope} ->
        {:ok, "resp"}
      end do
      assert DummyStorage.store({@img, :scope}) == {:ok, "image.png"}
    end
  end

  test "map with a filename and path" do
    with_mock Combo.Storage.Adapters.S3,
      put: fn DummyStorage, _, {%{file_name: "image.png", path: @img}, nil} ->
        {:ok, "resp"}
      end do
      assert DummyStorage.store(%{filename: "image.png", path: @img}) == {:ok, "image.png"}
    end
  end

  test "two-tuple with Plug.Upload and a scope" do
    with_mock Combo.Storage.Adapters.S3,
      put: fn DummyStorage, _, {%{file_name: "image.png", path: @img}, :scope} ->
        {:ok, "resp"}
      end do
      assert DummyStorage.store({%{filename: "image.png", path: @img}, :scope}) ==
               {:ok, "image.png"}
    end
  end

  test "error from ExAws on upload to S3" do
    with_mock Combo.Storage.Adapters.S3,
      put: fn DummyStorage, _, {%{file_name: "image.png", path: @img}, :scope} ->
        {:error, {:http_error, 404, "XML"}}
      end do
      assert DummyStorage.store({%{filename: "image.png", path: @img}, :scope}) ==
               {:error, [{:http_error, 404, "XML"}, {:http_error, 404, "XML"}]}
    end
  end

  test "timeout" do
    Application.put_env(:waffle, :version_timeout, 1)

    catch_exit do
      with_mock Combo.Storage.Adapters.S3,
        put: fn DummyStorage, _, {%{file_name: "image.png", path: @img}, :scope} ->
          :timer.sleep(100) && {:ok, "favicon.ico"}
        end do
        assert DummyStorage.store({%{filename: "image.png", path: @img}, :scope}) ==
                 {:ok, "image.png"}
      end
    end

    Application.put_env(:waffle, :version_timeout, 15_000)
  end
end
