defmodule AvailabilityManager do
  use Supervisor
  alias AvailabilityManager.{NotifierWatcher, Manager, SlotCreator}

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, notifier} = GenEvent.start_link

    children = [
      worker(NotifierWatcher, [notifier, notifiers])
    ]

    children = children ++
      Enum.map(store_ids, fn store_id ->
        slots = SlotCreator.generate_slots(store_id)
        worker(Manager, [store_id, slots, notifier])
      end)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AvailabilityManager.Supervisor]
    supervise(children, opts)
  end

  defp store_ids, do: [1]
  defp notifiers, do: config[:notifiers]

  defp config do
    Application.get_env(:scheduler_demo, :availability_manager)
  end
end
