defmodule WaffleTest.Storage.Local do
  use ExUnit.Case

  alias Combo.Storage.Adapters.Local

  @img "test/support/image.png"
  @badimg "test/support/invalid_image.png"

  setup do
    File.mkdir_p("waffletest/uploads")
    File.mkdir_p("waffletest/tmp")
    System.put_env("TMPDIR", "waffletest/tmp")

    on_exit(fn ->
      File.rm_rf("waffletest/uploads")
      File.rm_rf("waffletest/tmp")
    end)
  end

  def with_env(app, key, value, fun) do
    previous = Application.get_env(app, key, :nothing)

    Application.put_env(app, key, value)
    fun.()

    case previous do
      :nothing -> Application.delete_env(app, key)
      _ -> Application.put_env(app, key, previous)
    end
  end

  defmodule DummyStorage do
    use Combo.Storage

    @versions [:original, :thumb, :skipped]

    def transform(:thumb, _), do: {:convert, "-strip -thumbnail 10x10"}
    def transform(:original, _), do: :noaction
    def transform(:skipped, _), do: :skip

    def storage_dir(_, _), do: "waffletest/uploads"
    def __storage, do: Local

    def filename(:original, {file, _}),
      do: "original-#{Path.basename(file.file_name, Path.extname(file.file_name))}"

    def filename(:thumb, {file, _}),
      do: "1/thumb-#{Path.basename(file.file_name, Path.extname(file.file_name))}"

    def filename(:skipped, {file, _}),
      do: "1/skipped-#{Path.basename(file.file_name, Path.extname(file.file_name))}"
  end

  test "put, delete, get" do
    assert {:ok, "original-image.png"} ==
             Local.put(
               DummyStorage,
               :original,
               {Combo.Storage.File.new(%{filename: "original-image.png", path: @img}), nil}
             )

    assert {:ok, "1/thumb-image.png"} ==
             Local.put(
               DummyStorage,
               :thumb,
               {Combo.Storage.File.new(%{filename: "1/thumb-image.png", path: @img}), nil}
             )

    assert File.exists?("waffletest/uploads/original-image.png")
    assert File.exists?("waffletest/uploads/1/thumb-image.png")
    assert "/waffletest/uploads/original-image.png" == DummyStorage.url("image.png", :original)
    assert "/waffletest/uploads/1/thumb-image.png" == DummyStorage.url("1/image.png", :thumb)

    :ok = Local.delete(DummyStorage, :original, {%{file_name: "image.png"}, nil})
    :ok = Local.delete(DummyStorage, :thumb, {%{file_name: "image.png"}, nil})
    refute File.exists?("waffletest/uploads/original-image.png")
    refute File.exists?("waffletest/uploads/1/thumb-image.png")
  end

  test "deleting when there's a skipped version" do
    DummyStorage.store(@img)
    assert :ok = DummyStorage.delete(@img)
  end

  test "save binary" do
    Local.put(
      DummyStorage,
      :original,
      {Combo.Storage.File.new(%{binary: "binary", filename: "binary.png"}), nil}
    )

    assert true == File.exists?("waffletest/uploads/binary.png")
  end

  test "encoded url" do
    url =
      DummyStorage.url(
        Combo.Storage.File.new(%{binary: "binary", filename: "binary file.png"}),
        :original
      )

    assert "/waffletest/uploads/original-binary%20file.png" == url
  end

  test "url for skipped version" do
    url =
      DummyStorage.url(
        Combo.Storage.File.new(%{binary: "binary", filename: "binary file.png"}),
        :skipped
      )

    assert url == nil
  end

  test "if one transform fails, they all fail" do
    filepath = @badimg
    [filename] = String.split(@img, "/") |> Enum.reverse() |> Enum.take(1)
    assert File.exists?(filepath)
    DummyStorage.store(filepath)

    assert !File.exists?("waffletest/uploads/original-#{filename}")
    assert !File.exists?("waffletest/uploads/1/thumb-#{filename}")
  end

  test "temp files from processing are cleaned up" do
    filepath = @img
    DummyStorage.store(filepath)
    assert Enum.empty?(File.ls!("waffletest/tmp"))
  end

  test "temp files from handling binary data are cleaned up" do
    filepath = @img
    filename = "image.png"
    DummyStorage.store(%{binary: File.read!(filepath), filename: filename})
    assert File.exists?("waffletest/uploads/original-#{filename}")
    assert Enum.empty?(File.ls!("waffletest/tmp"))
  end

  test "temp files from handling remote URLs are cleaned up" do
    DummyStorage.store("https://www.google.com/favicon.ico")
    assert Enum.empty?(File.ls!("waffletest/tmp"))
  end
end
