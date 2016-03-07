defmodule AvailabilityManager.ReservationTrackerTest do
  use ExUnit.Case, async: true
  alias AvailabilityManager.ReservationTracker

  setup do
    store_id = 1000
    {date, _} = :calendar.local_time()

    slots = [
      {date, {11,0,0}, {:total, 2}},
      {date, {11,15,0}, {:total, 1}},
      {date, {11,30,0}, {:total, 5}}
    ]

    {:ok, notifier} = GenEvent.start_link
    {:ok, pid} = ReservationTracker.start_link(store_id, notifier)

    # Setup the table and send to the ReservationTracker
    table = :ets.new(__MODULE__, [:bag])
    :ets.insert(table, slots)
    :ets.give_away(table, pid, {})

    {:ok, store_id: store_id, date: date}
  end

  test "can hold a reservation", %{store_id: store_id, date: date} do
    time = {11,0,0}
    timeslot = {date, time}
    order_id = "123"

    result = ReservationTracker.hold(store_id, order_id, timeslot)
    assert result == :ok

    lookup = ReservationTracker.lookup(store_id, order_id)
    refute lookup == nil
  end

  test "cannot hold when there is no availability", %{store_id: store_id, date: date} do
    time = {11,15,0}
    timeslot = {date, time}

    # Hold a reseveration (only 1 slot for this time)
    ReservationTracker.hold(store_id, "123", timeslot)

    # Try an hold a second reservation
    result = ReservationTracker.hold(store_id, "234", timeslot)
    assert result == {:error, :not_available}
  end

  test "counts the number of a type", %{store_id: store_id, date: date} do
    time = {11,0,0}
    timeslot = {date, time}

    ReservationTracker.hold(store_id, "123", timeslot)
    ReservationTracker.hold(store_id, "234", timeslot)

    num = ReservationTracker.num_of_type(store_id, date, time, :pending)
    assert num == 2
  end

  test "can return the availability table for a given day", %{store_id: store_id, date: date} do
    actual = ReservationTracker.availability(store_id, date)
    expected = [
      {date, {11, 0, 0}, %{available: 2, total: 2}},
      {date, {11, 15, 0}, %{available: 1, total: 1}},
      {date, {11, 30, 0}, %{available: 5, total: 5}}
    ]

    assert actual == expected
  end

  test "can return the availability table", %{store_id: store_id, date: date} do
    actual = ReservationTracker.availability(store_id)
    expected = [
      {date, {11, 0, 0}, %{available: 2, total: 2}},
      {date, {11, 15, 0}, %{available: 1, total: 1}},
      {date, {11, 30, 0}, %{available: 5, total: 5}}
    ]

    assert actual == expected
  end

  test "can return an accurate availability table for a given day", %{store_id: store_id, date: date} do
    ReservationTracker.hold(store_id, "123", {date, {11, 0, 0}})
    ReservationTracker.hold(store_id, "234", {date, {11, 15, 0}})

    actual = ReservationTracker.availability(store_id, date)
    expected = [
      {date, {11, 0, 0}, %{available: 1, total: 2}},
      {date, {11, 15, 0}, %{available: 0, total: 1}},
      {date, {11, 30, 0}, %{available: 5, total: 5}}
    ]

    assert actual == expected
  end

  test "can remove a held order", %{store_id: store_id, date: date} do
    order_id = "123"
    ReservationTracker.hold(store_id, order_id, {date, {11, 0, 0}})
    ReservationTracker.remove(store_id, order_id)

    lookup = ReservationTracker.lookup(store_id, order_id)
    assert lookup == nil
  end

  test "can confirm a held order", %{store_id: store_id, date: date} do
    order_id = "123"

    ReservationTracker.hold(store_id, order_id, {date, {11, 0, 0}})

    result = ReservationTracker.confirm(store_id, order_id)
    assert result == :ok

    {_, _, {type, _, _}} = ReservationTracker.lookup(store_id, order_id)
    assert type == :confirmed
  end

  test "cannot confirm a non held order", %{store_id: store_id} do
    order_id = "123"

    result = ReservationTracker.confirm(store_id, order_id)
    assert result == {:error, :not_found}
  end

  test "can remove a confirmed order", %{store_id: store_id, date: date} do
    order_id = "123"

    ReservationTracker.hold(store_id, order_id, {date, {11, 0, 0}})
    ReservationTracker.confirm(store_id, order_id)
    ReservationTracker.remove(store_id, order_id)

    assert ReservationTracker.lookup(store_id, order_id) == nil
  end

  test "can retrieve a list of confirmed order ids for a given timeslot", %{store_id: store_id, date: date} do
    order_id = "123"
    time = {11, 0, 0}

    ReservationTracker.hold(store_id, order_id, {date, time})
    ReservationTracker.confirm(store_id, order_id)

    assert ReservationTracker.confirmed_orders(store_id, date, time) == [order_id]
  end

  test "can expire a currently held reservation", %{store_id: store_id, date: date} do
    order_id = "123"

    ReservationTracker.hold(store_id, order_id, {date, {11, 0, 0}})
    ReservationTracker.expire(store_id, order_id)

    assert ReservationTracker.lookup(store_id, order_id) == nil
  end
end
