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

  ## Local configuration

      config :waffle,
        # add custom host to url
        asset_host: "https://example.com"

  """

  use Combo.Storage.Adapter,
    requried_config: [:root]

  alias Waffle.Definition.Versioning

  @impl true
  def put(definition, version, {file, scope}) do
    destination_path =
      Path.join([
        definition.storage_dir(version, {file, scope}),
        file.file_name
      ])

    destination_path |> Path.dirname() |> File.mkdir_p!()

    if binary = file.binary do
      File.write!(destination_path, binary)
    else
      File.copy!(file.path, destination_path)
    end

    {:ok, file.file_name}
  end

  @impl true
  def url(definition, version, file_and_scope, _options \\ []) do
    local_path =
      Path.join([
        definition.storage_dir(version, file_and_scope),
        Versioning.resolve_file_name(definition, version, file_and_scope)
      ])

    host = host(definition)

    if host == nil do
      Path.join("/", local_path)
    else
      Path.join([host, local_path])
    end
    |> URI.encode()
  end

  @impl true
  def delete(definition, version, file_and_scope) do
    Path.join([
      definition.storage_dir(version, file_and_scope),
      Versioning.resolve_file_name(definition, version, file_and_scope)
    ])
    |> File.rm()
  end

  defp host(definition) do
    case definition.asset_host() do
      {:system, env_var} when is_binary(env_var) -> System.get_env(env_var)
      url -> url
    end
  end
end
