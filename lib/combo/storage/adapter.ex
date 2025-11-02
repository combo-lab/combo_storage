defmodule Combo.Storage.Adapter do
  @moduledoc """
  The specification for storage adapter.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @required_config opts[:required_config] || []
      @required_deps opts[:required_deps] || []

      @behaviour Combo.Storage.Adapter

      def validate_config(config) do
        Combo.Storage.Adapter.validate_config(@required_config, config)
      end

      def validate_deps do
        Combo.Storage.Adapter.validate_deps(@required_deps)
      end
    end
  end

  @doc """
  Saves a file and returns the file name or an error.
  """
  @callback put(
              definition :: atom,
              version :: atom,
              file_and_scope :: {Combo.Storage.File.t(), any}
            ) ::
              {:ok, file_name :: String.t()} | {:error, reason :: any}

  @doc """
  Generates a URL for accessing a file.
  """
  @callback url(
              definition :: atom,
              version :: atom,
              file_and_scope :: {Combo.Storage.File.t(), any}
            ) ::
              String.t()

  @doc """
  Deletes a file and returns the result of the operation.
  """
  @callback delete(
              definition :: atom,
              version :: atom,
              file_and_scope :: {Combo.Storage.File.t(), any}
            ) ::
              atom

  @spec validate_config([atom()], Keyword.t()) :: :ok | no_return
  def validate_config(required_config, config) do
    missing_keys =
      Enum.reduce(required_config, [], fn key, missing_keys ->
        if config[key] in [nil, ""],
          do: [key | missing_keys],
          else: missing_keys
      end)

    raise_on_missing_config(missing_keys, config)
  end

  defp raise_on_missing_config([], _config), do: :ok

  defp raise_on_missing_config(key, config) do
    raise ArgumentError, """
    expected #{inspect(key)} to be set, got: #{inspect(config)}
    """
  end

  @spec validate_deps([module | {atom, module}]) :: :ok | {:error, [module | {:atom | module}]}
  def validate_deps(required_deps) do
    if Enum.all?(required_deps, fn
         {_lib, module} -> Code.ensure_loaded?(module)
         module -> Code.ensure_loaded?(module)
       end),
       do: :ok,
       else: {:error, required_deps}
  end
end
