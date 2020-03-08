defmodule NosProtocol.Portal.Socket do
  defstruct socket: nil,
            crypto: nil,
            transport: nil,
            transport_pid: nil,
            assigns: %{},
            timeout: 0

  def assign(%__MODULE__{} = socket, key, value) when is_atom(key) do
    %{socket | assigns: Map.put(socket.assigns, key, value)}
  end

  def recv_packet(%__MODULE__{} = socket) do
    :ok = socket.transport.setopts(socket.socket, active: :once)
    {ok, closed, error} = socket.transport.messages()

    receive do
      {^ok, ^socket, data} ->
        {:ok, socket.crypto.decrypt(data)}

      {^error, ^socket, reason} ->
        {:error, {:socket_error, reason}}

      {^closed, ^socket} ->
        {:error, {:socket_error, :closed}}
    after
      socket.timeout ->
        {:error, :timeout}
    end
  end

  def send(%__MODULE__{} = socket, packet) do
    socket.transport.send(socket.socket, socket.crypto.encrypt(packet))
  end

  def close(%__MODULE__{} = socket) do
    socket.transport.close(socket.socket)
  end
end
