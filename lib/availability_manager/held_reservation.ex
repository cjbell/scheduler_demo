defmodule AvailabilityManager.HeldReservation do
  use GenServer
  @wait_until 10000

  def start_link(on_exit) do
    GenServer.start_link(__MODULE__, on_exit)
  end

  def init(on_exit) do
    timer = start_timer()
    {:ok, {on_exit, timer}}
  end

  def handle_info(:renew, {on_exit, timer}) do
    Process.cancel_timer(timer)
    timer = start_timer()

    {:noreply, {on_exit, timer}}
  end

  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  defp start_timer do
    Process.send_after(self, :shutdown, @wait_until)
  end

  def terminate(:normal, {on_exit, _}) do
    on_exit.()
  end
end
