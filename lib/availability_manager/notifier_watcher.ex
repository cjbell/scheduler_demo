defmodule AvailabilityManager.NotifierWatcher do
  use GenServer
  require Logger

  @doc """
    starts the GenServer, this should be done by a Supervisor to ensure
    restarts if it goes down
  """
  def start_link(notifier_pid, notifiers) do
    GenServer.start_link(__MODULE__, {notifier_pid, notifiers})
  end

  @doc """
    inits the GenServer by starting a new handler
  """
  def init({notifier_pid, notifiers}) do
    Logger.info "Starting #{length(notifiers)} notifier handlers"
    start_handlers(notifier_pid, notifiers)

    {:ok, notifier_pid}
  end

  @doc """
    handles EXIT messages from the GenEvent handler and restarts it
  """
  def handle_info({:gen_event_EXIT, handler, _reason}, notifier_pid) do
    Logger.info "Notifier #{handler} went DOWN. Restarting."
    {:ok, notifier_pid} = start_handler(notifier_pid, handler)
    {:noreply, notifier_pid}
  end

  defp start_handlers(notifier_pid, notifiers) do
    Enum.map(notifiers, &start_handler(notifier_pid, &1))
  end

  defp start_handler(notifier_pid, handler) do
    case GenEvent.add_mon_handler(notifier_pid, handler, []) do
     :ok ->
        Logger.info("Started handler #{handler}")
        {:ok, notifier_pid}
     {:error, reason} ->
        Logger.error("Could not start handler #{handler} for #{reason}")
        {:stop, reason}
    end
  end
end
