defmodule AvailabilityManager do
  use Supervisor
  @name AvailabilityManager

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def init([]) do
    children = Enum.map(store_ids, fn store_id ->
      supervisor(AvailabilityManager.Supervisor, [store_id, notifiers])
    end)

    supervise(children, strategy: :one_for_one)
  end

  defp store_ids, do: [1]
  defp notifiers, do: config[:notifiers]

  defp config do
    Application.get_env(:scheduler_demo, :availability_manager)
  end
end
