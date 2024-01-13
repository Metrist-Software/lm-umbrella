defmodule LmCommon.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    LmCommon.set_umbrella_app_logger_metadata(__MODULE__)
    children = [
      {Phoenix.PubSub, name: LmCommon.PubSub},
      finch()
    ]

    opts = [strategy: :one_for_one, name: LmCommon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp finch() do
    {Finch,
     name: Lm.Finch,
     pools: %{
       default: [
         conn_opts: [
           transport_opts: [
             verify: :verify_none
           ]
         ]
       ]
     }}
  end
end
