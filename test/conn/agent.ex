defmodule(Conn.Agent, do: defstruct([:res]))

defimpl Conn, for: Conn.Agent do
  def init(conn, res: agent) do
    if Process.alive?(agent) do
      {:ok, %{conn | res: agent}}
    else
      {:error, :dead, :infinity, conn}
    end
  end

  def init(conn, fun) do
    case Agent.start_link(fun) do
      {:ok, agent} ->
        init(conn, res: agent)

      :ignore ->
        {:error, :ignore, :infinity, conn}

      {:error, reason} ->
        {:error, reason, :infinity, conn}
    end
  end

  def resource(%_{res: agent}), do: agent

  def methods(_conn), do: [:get, :get_and_update, :update, :stop]

  def call(conn, method, fun \\ nil)

  def call(%_{res: agent} = conn, method, fun) when method in [:get, :get_and_update, :update] do
    {:ok, apply(Agent, method, [agent, fun]), 0, conn}
  end

  def call(%_{res: agent} = conn, :stop, nil) do
    Agent.stop(agent)
    {:ok, :closed, conn}
  end

  def parse(_conn, _data), do: {:error, :notimplemented}
end