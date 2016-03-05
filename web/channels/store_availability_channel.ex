defmodule SchedulerDemo.StoreAvailabilityChannel do
  use SchedulerDemo.Web, :channel

  intercept ["update"]

  def join("store_availability:" <> store, %{"orderId" => order_id}, socket) do
    socket =
      socket
      |> assign(:store, store)
      |> assign(:order_id, order_id)

    send self, :after_join
    {:ok, socket}
  end

  def broadcast_change(store_id, date, slots) do
    payload = %{slots: parse_slots(slots)}
    SchedulerDemo.Endpoint.broadcast("store_availability:" <> to_string(store_id), "update", payload)
  end

  def handle_in("select_day", %{"date" => date}, socket) do
    socket = socket |> assign(:date, parse_date(date))
    slots = remaining_slots(socket.assigns.store, socket.assigns.date)
    push socket, "update", %{slots: slots}

    {:reply, :ok, socket}
  end

  def handle_in("select_timeslot", %{"time" => time}, socket) do
    %{store: store, date: date, order_id: order_id} = socket.assigns
    case AvailabilityManager.Manager.hold(store, order_id, {date, parse_time(time)}) do
      :ok ->
        slots = remaining_slots(socket.assigns.store, socket.assigns.date)
        broadcast! socket, "update", %{slots: slots}
        {:reply, :ok, socket}
      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_out("update", msg, socket) do
    timeslot = lookup_current_slot(socket.assigns.store, socket.assigns.order_id)
    push socket, "update", Map.put(msg, :currentTimeslot, timeslot)

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    timeslot = lookup_current_slot(socket.assigns.store, socket.assigns.order_id)
    slots = remaining_slots(socket.assigns.store)

    push socket, "initial", %{slots: slots, currentTimeslot: timeslot}
    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp remaining_slots(store) do
    AvailabilityManager.Manager.availability(store)
    |> parse_slots
  end

  defp remaining_slots(store, date) do
    AvailabilityManager.Manager.availability(store, date)
    |> parse_slots
  end

  defp parse_slots(slots) do
    Enum.map(slots, fn {date, time, body} ->
      body
      |> Map.put(:time, time_to_string(time))
      |> Map.put(:date, date_to_string(date))
    end)
  end

  defp lookup_current_slot(store_id, order_id) do
    AvailabilityManager.Manager.lookup(store_id, order_id)
    |> case do
      {date, time, _} ->
        %{date: date_to_string(date),
          time: time_to_string(time)}
      _ -> nil
    end
  end

  defp parse_date(<<year::bytes-size(4),_::bytes-size(1), month::bytes-size(2),_::bytes-size(1),day::bytes-size(2)>>) do
    {String.to_integer(year), String.to_integer(month), String.to_integer(day)}
  end

  defp parse_time(<<hour::bytes-size(2),_::bytes-size(1),min::bytes-size(2),_::bytes-size(1),sec::bytes-size(2)>>) do
    {String.to_integer(hour), String.to_integer(min), String.to_integer(sec)}
  end

  defp date_to_string(date), do: datetime_to_string(date, "-")
  defp time_to_string(time), do: datetime_to_string(time, ":")

  defp datetime_to_string(date_or_time, join) do
    date_or_time
    |> Tuple.to_list
    |> Enum.map(fn val ->
      val |> to_string |> String.rjust(2, ?0)
    end)
    |> Enum.join(join)
  end
end
