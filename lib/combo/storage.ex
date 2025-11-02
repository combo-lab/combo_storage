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

  defmacro __using__(_options) do
    quote do
      use Waffle.Definition.Storage
      use Waffle.Definition.Versioning

      use Waffle.Actions.Store
      use Waffle.Actions.Delete
      use Waffle.Actions.Url
    end
  end
end
