defmodule NervesSSH.Exec do
  @moduledoc """
  This module contains helper methods for running commands over SSH
  """

  alias NervesSSH.SCP

  @doc """
  Run one Elixir command coming over ssh
  """
  @spec run_elixir(charlist()) :: {:ok, binary()} | {:error, binary()}
  def run_elixir(cmd) do
    cmd = to_string(cmd)

    cond do
      SCP.scp_command?(cmd) ->
        SCP.run(cmd)

      true ->
        run(cmd)
    end
  end

  defp run(cmd) do
    {result, _env} = Code.eval_string(cmd)
    {:ok, inspect(result)}
  catch
    kind, value ->
      {:error, Exception.format(kind, value, __STACKTRACE__)}
  end
end
