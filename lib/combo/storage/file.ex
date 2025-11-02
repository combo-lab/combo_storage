defmodule Combo.Storage.File do
  @moduledoc false

  # TODO: rename :file_name to :filename
  defstruct [:path, :file_name, :binary, :is_tempfile?, :stream]

  def generate_temporary_path(item \\ nil) do
    do_generate_temporary_path(item)
  end

  ## Handle a binary blob

  def new(%{filename: filename, binary: binary}, _definition) do
    %Combo.Storage.File{binary: binary, file_name: Path.basename(filename)}
    |> write_binary()
  end

  ## Handle a local file

  # Accepts a path
  def new(path, _definition) when is_binary(path) do
    case File.exists?(path) do
      true -> %Combo.Storage.File{path: path, file_name: Path.basename(path)}
      false -> {:error, :invalid_file_path}
    end
  end

  # Accepts a map conforming to %Plug.Upload{} syntax
  def new(%{filename: filename, path: path}, _definition) do
    case File.exists?(path) do
      true -> %Combo.Storage.File{path: path, file_name: filename}
      false -> {:error, :invalid_file_path}
    end
  end

  ## Handle a stream

  def new(%{filename: filename, stream: stream}, _definition) when is_struct(stream) do
    %Combo.Storage.File{stream: stream, file_name: Path.basename(filename)}
  end

  defp write_binary(file) do
    path = generate_temporary_path(file)
    File.write!(path, file.binary)

    %__MODULE__{
      file_name: file.file_name,
      path: path,
      is_tempfile?: true
    }
  end

  #
  # Temp file with exact extension.
  # Used for converting formats when passing extension in transformations
  #

  defp do_generate_temporary_path(%Combo.Storage.File{path: path}) do
    Path.extname(path || "")
    |> do_generate_temporary_path()
  end

  defp do_generate_temporary_path(extension) do
    ext = extension |> to_string()

    string_extension =
      cond do
        String.starts_with?(ext, ".") ->
          ext

        ext == "" ->
          ""

        true ->
          ".#{ext}"
      end

    file_name =
      :crypto.strong_rand_bytes(20)
      |> Base.encode32()
      |> Kernel.<>(string_extension)

    Path.join(System.tmp_dir(), file_name)
  end
end
