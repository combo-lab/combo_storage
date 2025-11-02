defmodule Combo.Storage.File do
  @moduledoc false

  # TODO: rename :file_name to :filename
  defstruct [:path, :file_name, :binary, :stream, :is_tempfile?]

  ## Handle a local file

  # Accepts a path
  def new(path) when is_binary(path) do
    case File.exists?(path) do
      true -> %Combo.Storage.File{path: path, file_name: Path.basename(path)}
      false -> {:error, :invalid_file_path}
    end
  end

  # Accepts a map conforming to %Plug.Upload{} syntax
  def new(%{filename: filename, path: path}) do
    case File.exists?(path) do
      true -> %Combo.Storage.File{path: path, file_name: filename}
      false -> {:error, :invalid_file_path}
    end
  end

  ## Handle a binary blob

  def new(%{filename: filename, binary: binary}) do
    ext = Path.extname(filename)
    tmp_path = build_tmp_path(ext)
    file_name = Path.basename(filename)
    File.write!(tmp_path, binary)
    %Combo.Storage.File{path: tmp_path, file_name: file_name, is_tempfile?: true}
  end

  ## Helpers

  def build_tmp_path(%Combo.Storage.File{} = file) do
    ext = Path.extname(file.path)
    build_tmp_path(ext)
  end

  def build_tmp_path(ext) when is_atom(ext) or is_binary(ext) do
    ext =
      ext
      |> to_string()
      |> add_dot_to_ext()

    name =
      :crypto.strong_rand_bytes(20)
      |> Base.encode32()
      |> Kernel.<>(ext)

    Path.join(System.tmp_dir(), name)
  end

  defp add_dot_to_ext("." <> _ = ext), do: ext
  defp add_dot_to_ext(""), do: ""
  defp add_dot_to_ext(ext), do: ".#{ext}"
end
