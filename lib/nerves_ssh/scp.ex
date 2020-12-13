defmodule NervesSSH.SCP do
  require Logger

  @doc """
  Determines whether a command to exec should be handled by scp
  """
  def scp_command?("scp -" <> _rest), do: true
  def scp_command?(_other), do: false

  @doc """
  Run the SCP command.
  """
  def run("scp " <> options) do
    Logger.info("getopts: #{inspect :io.getopts()}")
    #:io.setopts( binary: true)
    {path, args} = parse_args(options)

    Logger.info("scp: #{inspect(args)}")

    cond do
      :upload in args -> upload(path)
      :download in args -> download(path)
      true -> :ok
    end

    Logger.info("scp: done")
    {:ok, []}
  end

  defp parse_args(string, args \\ [])
  defp parse_args("", args), do: :error
  defp parse_args(" " <> rest, args), do: parse_args(rest, args)
  defp parse_args("-v" <> rest, args), do: parse_args(rest, [:verbose | args])
  defp parse_args("-t" <> rest, args), do: parse_args(rest, [:upload | args])
  defp parse_args("-f" <> rest, args), do: parse_args(rest, [:download | args])
  defp parse_args(path, args), do: {path, args}

  defp parse_file_info("C" <> mode_size_path) do
    [mode_string, size_string, path] = String.split(mode_size_path, " ", parts: 3)
    {mode, ""} = Integer.parse(mode_string, 8)
    {size, ""} = Integer.parse(size_string, 10)
    {mode, size, String.trim(path)}
  end

  defp read_response() do
    case IO.binread(1) do
      [0] ->
        :ok

      [1] ->
        resp = IO.binread(:line)
        Logger.info("got: #{resp}")
        read_response()

      [2] ->
        {:error, IO.binread(:line)}
    end
  end

  defp send_response(:ok), do: IO.binwrite([0])
  defp send_response({:error, message}), do: IO.binwrite([2, message, ?\n])

  defp upload(dest_path) do
    # Send the "I am scp" byte
    send_response(:ok)

    file_info = IO.binread(:line) |> IO.iodata_to_binary()
    {_perms, size, src_path} = parse_file_info(file_info)

    Logger.info("Going to receive #{size} bytes from original filename #{src_path}")
    send_response(:ok)

    bytes = IO.binread(size) |> IO.iodata_to_binary()
    Logger.info("Got #{byte_size(bytes)} bytes!")
    send_response(:ok)

    :ok = read_response()

    Logger.info("Waiting")
  end

  defp download(source_path) do
    :ok = read_response()
    Logger.info("Got download request")
    IO.binwrite("C0644 6 #{source_path}\n")
    :ok = read_response()
    Logger.info("Got response")
    IO.binwrite("hello\n")
    send_response(:ok)
    Logger.info("sent data")
    :ok = read_response()
    Logger.info("Got last response")
  end
end
