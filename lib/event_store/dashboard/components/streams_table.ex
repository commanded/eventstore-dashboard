defmodule EventStore.Dashboard.Components.StreamsTable do
  alias EventStore.Page

  import Phoenix.LiveDashboard.PageBuilder
  import EventStore.Dashboard.Helpers

  # See: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.PageBuilder.html

  def render(event_store, _assigns) do
    table(
      columns: table_columns(),
      default_sort_by: :stream_id,
      id: :event_store_streams_table,
      row_attrs: &row_attrs/1,
      row_fetcher: &paginate_streams(event_store, &1, &2),
      title: "Streams"
    )
  end

  defp paginate_streams(event_store, params, node) do
    %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

    {:ok, %Page{entries: entries, total_entries: total_entries}} =
      rpc_event_store(node, event_store, :paginate_streams, [
        [page_size: limit, search: search, sort_by: sort_by, sort_dir: sort_dir]
      ])

    entries = Enum.map(entries, &Map.from_struct/1)

    {entries, total_entries}
  end

  defp table_columns do
    [
      %{
        field: :stream_id,
        header: "Id",
        header_attrs: [class: "pl-4"],
        cell_attrs: [class: "tabular-column-id pl-4"],
        sortable: :asc
      },
      %{
        field: :stream_uuid,
        header: "Stream identity",
        cell_attrs: [class: "tabular-column-name pl-4"],
        sortable: :asc
      },
      %{
        field: :stream_version,
        header: "Version",
        sortable: :asc
      },
      %{
        field: :created_at,
        header: "Created at",
        sortable: :asc
      },
      %{
        field: :deleted_at,
        header: "Deleted at",
        sortable: :asc
      }
    ]
  end

  defp row_attrs(table) do
    [
      {"phx-click", "show_stream"},
      {"phx-value-stream", table[:stream_uuid]},
      {"phx-page-loading", true}
    ]
  end
end
