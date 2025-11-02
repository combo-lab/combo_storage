defmodule Combo.Storage.Adapter do
  @moduledoc """
  Defines the behaviour for storage adapter.
  """

  @doc """
  Saves a file and returns the file name or an error.
  """
  @callback put(definition :: atom, version :: atom, file_and_scope :: {Combo.Storage.File.t(), any}) ::
              {:ok, file_name :: String.t()} | {:error, reason :: any}

  @doc """
  Generates a URL for accessing a file.
  """
  @callback url(definition :: atom, version :: atom, file_and_scope :: {Combo.Storage.File.t(), any}) ::
              String.t()

  @doc """
  Deletes a file and returns the result of the operation.
  """
  @callback delete(definition :: atom, version :: atom, file_and_scope :: {Combo.Storage.File.t(), any}) ::
              atom
end
