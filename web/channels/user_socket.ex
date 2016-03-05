defmodule SchedulerDemo.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "store_availability:*", SchedulerDemo.StoreAvailabilityChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(socket), do: nil
end
