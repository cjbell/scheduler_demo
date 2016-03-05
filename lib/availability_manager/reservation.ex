defmodule AvailabilityManager.Reservation do
  use GenServer
  defstruct timer: nil,
            on_exit: nil

  @wait_until 10000

  def start_link(parent, order_id) do
    GenServer.start_link(__MODULE__, {parent, order_id})
  end

  def init({parent, order_id}) do
    timer = start_timer()
    {:ok, {parent, order_id, timer}}
  end

  def handle_info(:renew, {parent, order_id, timer}) do
    Process.cancel_timer(timer)
    timer = start_timer()

    {:noreply, {parent, order_id, timer}}
  end

  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  defp start_timer do
    Process.send_after(self, :shutdown, @wait_until)
  end

  def terminate(:normal, {parent, order_id, _}) do
    Process.send(parent, {:reservation_expired, order_id}, [])
  end
end
