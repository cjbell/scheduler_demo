use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :scheduler_demo, SchedulerDemo.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :scheduler_demo, SchedulerDemo.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "scheduler_demo_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
