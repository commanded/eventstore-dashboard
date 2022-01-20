defmodule EventStore.Dashboard.Helpers do
  @moduledoc false

  @doc """
  All connected nodes (including the current node).
  """
  def nodes(), do: [node()] ++ Node.list(:connected)

  def rpc_event_store(node, event_store, function, args \\ [])

  def rpc_event_store(node, event_store, function, args) do
    {module, opts} = event_store

    args = include_event_store_name(args, opts)

    case :rpc.call(node, module, function, args) do
      {:badrpc, _reason} = error ->
        {:error, error}

      nil ->
        {:error, :event_store_is_not_available}

      reply ->
        reply
    end
  end

  # Include event store name in Keyword option args
  defp include_event_store_name(args, opts) do
    name = Keyword.fetch!(opts, :name)

    case Enum.split(args, -1) do
      {args, [opts]} when is_list(opts) ->
        args ++ [Keyword.put(opts, :name, name)]

      _ ->
        args ++ [[name: name]]
    end
  end
end
