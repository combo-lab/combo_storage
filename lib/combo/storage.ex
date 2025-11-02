defmodule Combo.Storage do
  @moduledoc ~S"""
  Defines the storage module to manage files.

      defmodule MyApp.Core.Avatar do
        use Combo.Storage
      end

  Consists of several components to manage different parts of file
  managing process.

    * `Waffle.Definition.Versioning`
    * `Waffle.Definition.Storage`
    * `Waffle.Actions.Store`
    * `Waffle.Actions.Delete`
    * `Waffle.Actions.Url`

  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Waffle.Definition.Storage
      use Waffle.Definition.Versioning

      use Waffle.Actions.Store
      use Waffle.Actions.Delete
      use Waffle.Actions.Url

      @storage_config opts

      @before_compile {Combo.Storage, :__inject_default_callbacks__}
    end
  end

  @type message :: binary()
  @type file_and_scope :: {Combo.Storage.File.t(), any()}
  @type variant :: atom()
  @type path :: binary()

  @callback validate(file_and_scope()) ::
              :ok | {:error, message()}
  @callback transform(file_and_scope(), variant()) ::
              {:ok, Combo.Storage.File.t()} | {:error, message()}
  @callback build_path(file_and_scope(), variant()) :: path()

  defmacro __inject_default_callbacks__(_env) do
    quote do
      def validate(_), do: :ok
      def transform({file, _}, _), do: {:ok, file}
      def build_path({file, _}, _), do: Path.basename(file.file_name)

      defoverridable validate: 1,
                     transform: 2
    end
  end
end
