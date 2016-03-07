defmodule AvailabilityManager.Supervisor do
  use Supervisor
  alias AvailabilityManager.{NotifierWatcher, Manager, SlotCreator}

  def start_link(store_id, notifiers) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {store_id, notifiers})
  end

  def init({store_id, notifiers}) do
    {:ok, notifier} = GenEvent.start_link
    slots = SlotCreator.generate_slots(store_id)
    manager_name = Manager.ref(store_id)

    children = [
      worker(NotifierWatcher, [notifier, notifiers]),
      worker(Manager, [store_id, slots, notifier]),
      worker(Immortal.ETSTableManager, [manager_name, [:bag]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
