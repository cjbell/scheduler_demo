ExUnit.start

Mix.Task.run "ecto.create", ~w(-r SchedulerDemo.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r SchedulerDemo.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(SchedulerDemo.Repo)

