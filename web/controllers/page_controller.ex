defmodule SchedulerDemo.PageController do
  use SchedulerDemo.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
