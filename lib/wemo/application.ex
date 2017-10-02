defmodule WeMo.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # List all child processes to be supervised
    children = [
      worker(WeMo.HTTPRouter, []),
      worker(WeMo.Client, []),
      supervisor(WeMo.InsightSupervisor, []),
      supervisor(WeMo.LightSwitchSupervisor, []),
    ]
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeMo.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
