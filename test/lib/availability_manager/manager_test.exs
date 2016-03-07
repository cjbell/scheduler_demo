defmodule AvailabilityManager.ManagerTest do
  use ExUnit.Case, async: true
  alias AvailabilityManager.Manager

  setup do
    store_id = 1000
    {date, _} = :calendar.local_time()

    slots = [
      {date, {11,0,0}, {:total, 2}},
      {date, {11,15,0}, {:total, 1}},
      {date, {11,30,0}, {:total, 5}}
    ]

    {:ok, notifier} = GenEvent.start_link
    {:ok, pid} = Manager.start_link(store_id, slots, notifier)

    # Setup the table and send to the manager
    table = :ets.new(__MODULE__, [:bag])
    :ets.give_away(table, pid, {})

    {:ok, store_id: store_id, date: date, slots: slots}
  end

  test "can hold a reservation", %{store_id: store_id, date: date} do
    time = {11,0,0}
    timeslot = {date, time}
    order_id = "123"

    result = Manager.hold(store_id, order_id, timeslot)
    assert result == :ok

    lookup = Manager.lookup(store_id, order_id)
    refute lookup == nil
  end

  test "cannot hold when there is no availability", %{store_id: store_id, date: date} do
    time = {11,15,0}
    timeslot = {date, time}

    # Hold a reseveration (only 1 slot for this time)
    Manager.hold(store_id, "123", timeslot)

    # Try an hold a second reservation
    result = Manager.hold(store_id, "234", timeslot)
    assert result == {:error, :not_available}
  end

  test "counts the number of a type", %{store_id: store_id, date: date} do
    time = {11,0,0}
    timeslot = {date, time}

    Manager.hold(store_id, "123", timeslot)
    Manager.hold(store_id, "234", timeslot)

    num = Manager.num_of_type(store_id, date, time, :pending)
    assert num == 2
  end

  test "can return the availability table for a given day", %{store_id: store_id, date: date} do
    actual = Manager.availability(store_id, date)
    expected = [
      {date, {11, 0, 0}, %{available: 2, total: 2}},
      {date, {11, 15, 0}, %{available: 1, total: 1}},
      {date, {11, 30, 0}, %{available: 5, total: 5}}
    ]

    assert actual == expected
  end

  test "can return the availability table", %{store_id: store_id, date: date} do
    actual = Manager.availability(store_id)
    expected = [
      {date, {11, 0, 0}, %{available: 2, total: 2}},
      {date, {11, 15, 0}, %{available: 1, total: 1}},
      {date, {11, 30, 0}, %{available: 5, total: 5}}
    ]

    assert actual == expected
  end

  test "can return an accurate availability table for a given day", %{store_id: store_id, date: date} do
    Manager.hold(store_id, "123", {date, {11, 0, 0}})
    Manager.hold(store_id, "234", {date, {11, 15, 0}})

    actual = Manager.availability(store_id, date)
    expected = [
      {date, {11, 0, 0}, %{available: 1, total: 2}},
      {date, {11, 15, 0}, %{available: 0, total: 1}},
      {date, {11, 30, 0}, %{available: 5, total: 5}}
    ]

    assert actual == expected
  end

  test "can remove a held order", %{store_id: store_id, date: date} do
    order_id = "123"
    Manager.hold(store_id, order_id, {date, {11, 0, 0}})
    Manager.remove(store_id, order_id)

    lookup = Manager.lookup(store_id, order_id)
    assert lookup == nil
  end

  test "can confirm a held order", %{store_id: store_id, date: date} do
    order_id = "123"

    Manager.hold(store_id, order_id, {date, {11, 0, 0}})

    result = Manager.confirm(store_id, order_id)
    assert result == :ok

    {_, _, {type, _, _}} = Manager.lookup(store_id, order_id)
    assert type == :confirmed
  end

  test "cannot confirm a non held order", %{store_id: store_id} do
    order_id = "123"

    result = Manager.confirm(store_id, order_id)
    assert result == {:error, :not_found}
  end

  test "can remove a confirmed order", %{store_id: store_id, date: date} do
    order_id = "123"

    Manager.hold(store_id, order_id, {date, {11, 0, 0}})
    Manager.confirm(store_id, order_id)
    Manager.remove(store_id, order_id)

    assert Manager.lookup(store_id, order_id) == nil
  end

  test "can retrieve a list of confirmed order ids for a given timeslot", %{store_id: store_id, date: date} do
    order_id = "123"
    time = {11, 0, 0}

    Manager.hold(store_id, order_id, {date, time})
    Manager.confirm(store_id, order_id)

    assert Manager.confirmed_orders(store_id, date, time) ==
           [order_id]
  end
end
