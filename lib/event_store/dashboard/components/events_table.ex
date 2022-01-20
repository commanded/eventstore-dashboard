defmodule EventStore.Dashboard.Components.EventsTable do
  alias EventStore.Streams.StreamInfo
  alias Phoenix.LiveDashboard.PageBuilder

  import EventStore.Dashboard.Helpers
  import Phoenix.LiveDashboard.PageBuilder

  def render(event_store, assigns) do
    %{page: %{params: params}} = assigns

    stream_uuid = parse_stream_uuid(params)

    if event_number = parse_event_number(params) do
      render_event_modal(event_store, assigns, stream_uuid, event_number)
    else
      render_events(event_store, stream_uuid)
    end
  end

  defp parse_stream_uuid(params) do
    case Map.get(params, "stream") do
      "" -> "$all"
      stream when is_binary(stream) -> stream
      nil -> "$all"
    end
  end

  defp parse_event_number(params) do
    case Map.get(params, "event") do
      "" -> nil
      event when is_binary(event) -> String.to_integer(event)
      nil -> nil
    end
  end

  defp render_event_modal(event_store, assigns, stream_uuid, event_number) do
    %{page: %{node: node, params: params} = page, socket: socket} = assigns

    params = Map.put(params, "event", nil)

    return_to =
      PageBuilder.live_dashboard_path(socket, page.route, node, params, Enum.into([], params))

    {Phoenix.LiveDashboard.ModalComponent,
     %{
       id: :modal,
       return_to: return_to,
       component: EventStore.Dashboard.Components.EventModal,
       opts: [
         id: :modal,
         return_to: return_to,
         title: "Event",
         event_store: event_store,
         node: node,
         stream_uuid: stream_uuid,
         event_number: event_number
       ],
       title: "Event"
     }}
  end

  defp render_events(event_store, stream_uuid) do
    title =
      if stream_uuid == "$all",
        do: "All stream events",
        else: "Stream #{inspect(stream_uuid)} events"

    table(
      columns: table_columns(stream_uuid),
      default_sort_by: :event_number,
      id: :event_store_streams_table,
      row_attrs: &row_attrs(&1, stream_uuid),
      row_fetcher: &read_stream(event_store, stream_uuid, &1, &2),
      rows_name: "events",
      title: title,
      search: false
    )
  end

  defp read_stream(event_store, stream_uuid, params, node) do
    with {:ok, %StreamInfo{} = stream} <- stream_info(node, event_store, stream_uuid),
         {:ok, recorded_events} <- recorded_events(node, event_store, stream_uuid, params) do
      %StreamInfo{stream_version: stream_version} = stream

      entries = Enum.map(recorded_events, &Map.from_struct/1)

      {entries, stream_version}
    else
      {:error, _error} -> {[], 0}
    end
  end

  defp stream_info(node, event_store, stream_uuid) do
    rpc_event_store(node, event_store, :stream_info, [stream_uuid])
  end

  defp recorded_events(node, event_store, stream_uuid, params) do
    %{sort_by: _sort_by, sort_dir: sort_dir, limit: limit} = params

    {read_stream_function, start_version} =
      case sort_dir do
        :asc -> {:read_stream_forward, 0}
        :desc -> {:read_stream_backward, -1}
      end

    rpc_event_store(node, event_store, read_stream_function, [stream_uuid, start_version, limit])
  end

  defp table_columns("$all") do
    [
      %{
        field: :event_number,
        header: "Event #",
        cell_attrs: [class: "tabular-column-name pl-4"],
        sortable: :asc
      },
      %{
        field: :event_id,
        header: "Event id",
        header_attrs: [class: "pl-4"],
        cell_attrs: [class: "tabular-column-id pl-4"]
      },
      %{
        field: :event_type,
        header: "Event type"
      },
      %{
        field: :stream_uuid,
        header: "Source stream",
        cell_attrs: [class: "tabular-column-name pl-4"]
      },
      %{
        field: :stream_version,
        header: "Source version"
      },
      %{
        field: :created_at,
        header: "Created at"
      }
    ]
  end

  defp table_columns(_stream_uuid) do
    [
      %{
        field: :event_number,
        header: "Event #",
        cell_attrs: [class: "tabular-column-name pl-4"],
        sortable: :asc
      },
      %{
        field: :event_id,
        header: "Event id",
        header_attrs: [class: "pl-4"],
        cell_attrs: [class: "tabular-column-id pl-4"]
      },
      %{
        field: :event_type,
        header: "Event type"
      },
      %{
        field: :created_at,
        header: "Created at"
      }
    ]
  end

  defp row_attrs(table, stream_uuid) do
    [
      {"phx-click", "show_event"},
      {"phx-value-stream", stream_uuid},
      {"phx-value-event", table[:event_number]},
      {"phx-page-loading", true}
    ]
  end
end
