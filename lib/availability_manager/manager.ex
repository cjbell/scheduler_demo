defmodule AvailabilityManager.Manager do
  alias AvailabilityManager.Reservation
  use GenServer
  require Logger

  def start_link(store_id, initial_slots, event_manager) do
    Logger.info "Starting AvailabilityManager for #{store_id}"
    state = {store_id, initial_slots, event_manager}
    GenServer.start_link(__MODULE__, state, name: ref(store_id))
  end

  @doc """
    Places a hold for the order on the given timeslot
  """
  def hold(store_id, order_id, {date, time}) do
    try_call store_id, {:hold, order_id, date, time}
  end

  @doc """
    Expires any pending orders of `order_id`
  """
  def expire(store_id, order_id) do
    try_call store_id, {:expire, order_id}
  end

  @doc """
    Remove an order from a store
  """
  def remove(store_id, order_id) do
    try_call store_id, {:remove, order_id}
  end

  @doc """
    Marks a `pending` order as confirmed and cleans up
    any reservation processes for the order
  """
  def confirm(store_id, order_id) do
    try_call store_id, {:confirm, order_id}
  end

  def lookup(store_id, order_id) do
    try_call store_id, {:lookup, order_id}
  end

  def num_of_type(store_id, date, type) do
    try_call store_id, {:num_of_type, date, type}
  end

  def num_of_type(store_id, date, time, type) do
    try_call store_id, {:num_of_type, date, time, type}
  end

  @doc """
    Returns the availability calendar for a given store
  """
  def availability(store_id) do
    try_call store_id, :availability
  end

  @doc """
    Returns the availability calendar for a given store on the given date
  """
  def availability(store_id, date) do
    try_call store_id, {:availability, date}
  end

  @doc """
    Returns an array of all confirmed orders for the given date and time
  """
  def confirmed_orders(store_id, date, time) do
    try_call store_id, {:confirmed_orders, date, time}
  end

  def init({store_id, initial_slots, event_manager}) do
    table = :ets.new __MODULE__, [:bag]
    :ets.insert table, initial_slots
    {:ok, {store_id, table, event_manager}}
  end

  def handle_call({:hold, order_id, date, time}, _, {_, table, _} = state) do
    if has_availablility?(table, date, time) do
      result =
        lookup_order(table, order_id)
        |> hold_order({order_id, date, time}, state)

      {:reply, result, state}
    else
      {:reply, {:error, :not_available}, state}
    end
  end

  def handle_call({:confirm, order_id}, _, {_, table, _} = state) do
    result =
      lookup_order(table, order_id)
      |> case do
        {date, time, {:pending, _, _}} ->
          remove_order(table, order_id, :pending)
          insert_order(table, date, time, :confirmed, order_id)
          :ok
        _ -> {:error, :not_found}
      end

    {:reply, result, state}
  end

  def handle_call({:expire, order_id}, _, {_, table, _} = state) do
    case lookup_order(table, order_id) do
      {_, _, {:pending, _, pid}} ->
        Process.send(:shutdown, pid)
        {:reply, :ok, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:lookup, order_id}, _, {_, table, _} = state) do
    {:reply, lookup_order(table, order_id), state}
  end

  def handle_call({:num_of_type, date, type}, _, {_, table, _} = state) do
    {:reply, count_type(table, date, nil, type), state}
  end

  def handle_call({:num_of_type, date, time, type}, _, {_, table, _} = state) do
    {:reply, count_type(table, date, time, type), state}
  end

  def handle_call(:availability, _, {_, table, _} = state) do
    {:reply, availability_list(table), state}
  end

  def handle_call({:availability, date}, _, {_, table, _} = state) do
    {:reply, availability_list(table, date), state}
  end

  def handle_call({:confirmed_orders, date, time}, _, {_, table, _} = state) do
    orders =
      :ets.match_object(table, build_table_match(date, time, :confirmed))
      |> Enum.map(fn {_, _, {_, order_id, _}} -> order_id end)

    {:reply, orders, state}
  end

  def handle_call({:remove, order_id}, _, {_, table, _} = state) do
    remove_order(table, order_id)
    {:reply, :ok, state}
  end

  def handle_info({:reservation_expired, order_id}, {store_id, table, event_manager} = state) do
    Logger.info "AvailabilityManager: Removing expired order #{order_id}"

    lookup_order(table, order_id)
    |> case do
      {date, _, {:pending, _, _}} ->
        remove_order(table, order_id, :pending)
        # Notify any listeners of the cancellation
        availability = availability_list(table, date)
        GenEvent.sync_notify(event_manager, {:update, store_id, date, availability})

      _ -> {:error, :not_exists}
    end

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def ref(store_id) do
    {:global, {:availability_manager, to_string(store_id)}}
  end

  def try_call(store_id, call_function) do
    case whereis(store_id) do
      nil -> {:error, :invalid}
      manager -> GenServer.call(manager, call_function)
    end
  end

  def whereis(store_id) do
    GenServer.whereis(ref(store_id))
  end

  ## Private order methods

  defp hold_order({_, _, {:pending, order_id, pid}}, {_, date, time}, {_, table, _}) do
    Process.send(pid, :renew, [])
    remove_order(table, order_id, :pending)
    insert_order(table, date, time, :pending, order_id, pid)
    :ok
  end

  defp hold_order({_, _, {:confirmed, _, _}}, _, _) do
    {:error, :not_available}
  end

  defp hold_order(_, {order_id, date, time}, {_, table, _}) do
    {:ok, pid} = Reservation.start_link(self, order_id)
    insert_order(table, date, time, :pending, order_id, pid)

    :ok
  end

  defp lookup_order(table, order_id) do
    :ets.match_object(table, build_table_match(:_, :_, :_, order_id))
    |> case do
      [] -> nil
      [item | _] -> item
    end
  end

  defp remove_order(table, order_id, type \\ :_) do
    :ets.match_delete(table, build_table_match(:_, :_, type, order_id))
  end

  defp insert_order(table, date, time, type, order_id, extra \\ nil) do
    :ets.insert(table, build_table_match(date, time, type, order_id, extra))
  end

  defp availability_list(table, date \\ :_) do
    totals_list(table, date)
    |> parse_availability_list(table)
  end

  defp has_availablility?(table, date, time) do
    totals_list(table, date, time)
    |> case do
      [{_, _, {_, total}} | _] ->
        pending   = count_type(table, date, time, :pending)
        confirmed = count_type(table, date, time, :confirmed)

        total - pending - confirmed > 0
      _ -> false
    end
  end

  defp totals_list(table, date, time \\ :_) do
    :ets.match_object(table, {date, time, {:total, :_}})
  end

  defp count_type(table, date, time, type) do
    select_args = [{build_table_match(date, time, type, :_), [], [true]}]
    :ets.select_count(table, select_args)
  end

  defp parse_availability_list(totals_list, table) do
    Enum.map(totals_list, fn {date, time, {_, total}} ->
      pending   = count_type(table, date, time, :pending)
      confirmed = count_type(table, date, time, :confirmed)

      {date, time, %{total: total, available: total - pending - confirmed}}
    end)
  end

  defp build_table_match(date, time, type, order_id \\ :_, pid \\ :_) do
    {date, time, {type, order_id, pid}}
  end
end
