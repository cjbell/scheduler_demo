defmodule AvailabilityManager.SlotCreator do
  def generate_slots(_) do
    {date, _} = :calendar.local_time()
    generate_slot(date)
  end

  def generate_slot(day), do: generate_slot(day, {11, 0, 0}, [])
  def generate_slot(day, {22, 15, 0} = time, slots), do: slots
  def generate_slot(day, {hour, minute, _} = time, slots) when minute == 45 do
    generate_slot(day, {hour + 1, 0, 0}, slots ++ [timeslot(day, time)])
  end
  def generate_slot(day, {hour, minute, _} = time, slots) do
    generate_slot(day, {hour, minute + 15, 0}, slots ++ [timeslot(day, time)])
  end

  def timeslot(day, time) do
    {day, time, {:total, 2}}
  end
end
