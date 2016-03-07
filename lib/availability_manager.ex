defmodule AvailabilityManager do
  use Supervisor
  alias AvailabilityManager.{NotifierWatcher, ReservationTracker, SlotCreator}

  def start_link(store_id) do
    Supervisor.start_link(__MODULE__, store_id)
  end

  def init(store_id) do
    {:ok, notifier} = GenEvent.start_link
    initial_slots = SlotCreator.generate_slots(store_id)
    manager_name = ReservationTracker.ref(store_id)

    children = [
      worker(NotifierWatcher, [notifier, notifiers]),
      worker(ReservationTracker, [store_id, notifier]),
      worker(ETSTableManager, [manager_name, [:bag], initial_slots])
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp notifiers, do: config[:notifiers]
  defp config do
    Application.get_env(:scheduler_demo, :availability_manager)
  end
end

