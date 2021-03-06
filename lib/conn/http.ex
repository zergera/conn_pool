defmodule Conn.HTTP do
  @moduledoc """
  This module represents HTTP-connection. It's a simple HTTPoison wrapper.

  To initialize, use `Conn.init/2` method:

      iex> {:ok, conn} = Conn.init(%Conn.HTTP{}, url: "https://google.com",
      ...>                                       mirror: "https://duckduckgo.com")
      iex> conn
      %Conn.HTTP{res: "https://google.com", url: "https://google.com", mirrors: ["https://duckduckgo.com"]}

  Call is made via `Conn.call/3` method:

      iex> {:ok, conn} =
      ...>   Conn.init(%Conn.HTTP{}, res: :search,
      ...>                           url: "https://google.com")
      iex> {:reply, resp, conn} =
      ...>   Conn.call(conn, :get, body: "", headers: [], follow_redirect: true)
      iex> resp.body =~ "Google"
      true
      #
      # Also this conn could be added to pool:
      iex> {:ok, pool} = Conn.Pool.start_link()
      iex> Conn.Pool.put!(pool, conn)
      iex> {:ok, resp} = Conn.Pool.call(pool, :search, :get, follow_redirect: true)
      iex> resp.body =~ "Google"
      true

  Also, mirrors could be provided:

      iex> {:ok, conn} =
      ...>   Conn.init(%Conn.HTTP{}, url: "https://gooooogel.com",
      ...>                           mirrors: ["https://gooooooooooooogel.com",
      ...>                                     "https://duckduckgo.com"])
      iex> {:reply, resp, ^conn} =
      ...>   Conn.call(conn, :get, follow_redirect: true)
      iex> resp.body =~ "duck"
      true

  The other option is to provide args to substitute to URLs:

      iex> {:ok, conn} =
      ...>   Conn.init(%Conn.HTTP{}, res: :search,
      ...>                           url: &"https://goooogel.com?q=\#{&1}",
      ...>                           mirror: &"https://duckduckgo.com/?q=\#{&1}")
      iex> {:reply, resp, ^conn} =
      ...>   Conn.call(conn, :get, args: ["follow the white rabbit"], follow_redirect: true)
      iex> resp.body =~ "follow"
      true
      iex> resp.body =~ "duck"
      true

  For other params see docs for `HTTPoison.request/5`.
  """
  defstruct [:res, :url, :mirrors]
end

defimpl Conn, for: Conn.HTTP do
  def init(conn, init_args \\ []) do
    u = init_args[:url] || init_args[:res] || raise(":url or :res must be provided!")
    r = init_args[:res] || u

    if is_function(r) do
      raise """
        :res opt was probably copied from :url, and URL was given as an
        anonymous function. This makes no sense. Please, provide custom :res
        opt that is not an anonymous fun.
      """
    end

    if init_args[:mirrors] && not is_list(init_args[:mirrors]) do
      raise ":mirrors opt should be a list."
    end

    if init_args[:mirror] && init_args[:mirrors] do
      raise "Either :mirror or :mirrors opt could be given. Not both."
    end

    ms =
      init_args[:mirrors] ||
        if init_args[:mirror] do
          [init_args[:mirror]]
        end || []

    {:ok, %{conn | url: u, res: r, mirrors: ms}}
  end

  def resource(%_{res: r}), do: r

  def parse(_conn, _data), do: {:error, :notimplemented}

  def methods!(_conn), do: [:get, :post]

  def call(conn, method, params \\ [])

  def call(%_{url: u} = conn, method, params)
      when method in [:get, :head, :post, :put, :delete, :options, :patch] do
    url =
      if is_function(u) do
        unless params[:args] do
          raise ":args opt must be provided in order to use URLs in form of anonymous funs."
        end

        unless is_list(params[:args]) do
          raise ":args opt must be a list."
        end

        apply(u, params[:args])
      end || u

    case HTTPoison.request(method, url, params[:body] || "", params[:headers] || [], params) do
      {:ok, %HTTPoison.AsyncResponse{id: ref}} ->
        IO.inspect(:x)
        {:reply, ref, conn}

      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        IO.inspect(:y)
        {:reply, resp, conn}

      {:ok, resp} ->
        IO.inspect(:z)
        case conn.mirrors do
          [] ->
            {:reply, resp, conn}

          [m | ms] ->
            case call(%{conn | mirrors: ms, res: m}, method, params) do
              {:reply, resp, conn} ->
                {:reply, resp, %{conn | mirrors: [url | ms]}}

              {:error, reason, conn} ->
                {:error, reason, %{conn | mirrors: [url | ms]}}
            end
        end

      {:error, %HTTPoison.Error{reason: r}} ->
        IO.inspect(:a)
        {:error, r, conn}
    end
  end

  def call(_conn, _, _), do: {:error, :notsupported}
end
