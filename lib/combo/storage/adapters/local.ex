defmodule Combo.Storage.Adapters.Local do
  @moduledoc ~S"""
  Local storage provides facility to store files locally.

  ## Usage

      defmodule MyApp.Core.UserAvatar do
        use Combo.Storage,
          adapter: Combo.Storage.Adapters.Local,
          root: Application.app_dir(:my_app, "priv/uploads")
      end

  If you want to serve the files from a Combo application, configure the
  endpoint to match the `:root` option above:

      defmodule MyApp.Web.Endpoint do
        plug Plug.Static,
          at: "/uploads",
          from: {:my_app, "priv/uploads"}
          gzip: false
      end

  > In production, you might want to store files in a persistent location,
  > such as `/media`.

  """

  use Combo.Storage.Adapter,
    requried_config: [:root]

  alias Waffle.Definition.Versioning

  @impl true
  def put(definition, variant, {file, scope}) do
    dest_path =
      Path.join([
        definition.storage_dir(variant, {file, scope}),
        file.file_name
      ])

    dest_path |> Path.dirname() |> File.mkdir_p!()

    if binary = file.binary do
      File.write!(dest_path, binary)
    else
      File.copy!(file.path, dest_path)
    end

    {:ok, file.file_name}
  end

  @impl true
  def url(definition, variant, file_and_scope, _options \\ []) do
    local_path =
      Path.join([
        definition.storage_dir(variant, file_and_scope),
        Versioning.resolve_file_name(definition, variant, file_and_scope)
      ])

    URI.encode(Path.join("/", local_path))
  end

  @impl true
  def delete(definition, variant, file_and_scope) do
    Path.join([
      definition.storage_dir(variant, file_and_scope),
      Versioning.resolve_file_name(definition, variant, file_and_scope)
    ])
    |> File.rm()
  end
end
