defmodule SchedulerDemo.StoreAvailabilityNotifier do
  alias SchedulerDemo.StoreAvailabilityChannel
  use GenEvent
  require Logger

  def handle_event({:update, store_id, date, timeslots}, _) do
    StoreAvailabilityChannel.broadcast_change(store_id, date, timeslots)
    {:ok, []}
  end

  def handle_event(_, _) do
    {:ok, []}
  end
end
