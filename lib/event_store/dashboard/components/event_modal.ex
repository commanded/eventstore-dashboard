defmodule EventStore.Dashboard.Components.EventModal do
  use Phoenix.LiveDashboard.Web, :live_component

  import EventStore.Dashboard.Helpers

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign_event(socket, assigns)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    if assigns[:error] do
      ~H"""
      <div>
        <div class="alert alert-danger" role="alert">
          <%= @error %>
        </div>

        <div class="modal-footer">
          <button phx-click="navigate_to_previous_event" phx-value-event={@event_number} phx-target={@myself} class="btn btn-secondary">Previous event</button>
          <button phx-click="navigate_to_next_event" phx-value-event={@event_number} phx-target={@myself} class="btn btn-primary">Next event</button>
        </div>
      </div>
      """
    else
      ~H"""
      <div class="tabular-info">
        <table class="table table-hover tabular-info-table">
          <tbody>
            <tr>
              <td class="border-top-0">Id</td>
              <td class="border-top-0"><pre><%= @event.event_id %></pre></td>
            </tr>
            <tr>
              <td>Stream</td>
              <td><pre><%= @event.stream_uuid %></pre></td>
            </tr>
            <tr>
              <td>Position</td>
              <td><pre><%= @event.event_number %></pre></td>
            </tr>
            <tr>
              <td>Type</td>
              <td><pre><%= @event.event_type %></pre></td>
            </tr>
            <tr>
              <td>Causation id</td>
              <td><pre><%= @event.causation_id %></pre></td>
            </tr>
            <tr>
              <td>Correlation id</td>
              <td><pre><%= @event.correlation_id %></pre></td>
            </tr>
            <tr>
              <td>Created at</td>
              <td><pre><%= @event.created_at %></pre></td>
            </tr>
            <tr>
              <td>Data</td>
              <td><pre><%= inspect(@event.data, @inspect_opts) %></pre></td>
            </tr>
            <tr>
              <td>Metadata</td>
              <td><pre><%= inspect(@event.metadata, @inspect_opts) %></pre></td>
            </tr>
          </tbody>
        </table>

        <div class="modal-footer">
          <button phx-click="navigate_to_previous_event" phx-value-event={@event.event_number} phx-target={@myself} class="btn btn-secondary">Previous event</button>
          <button phx-click="navigate_to_next_event" phx-value-event={@event.event_number} phx-target={@myself} class="btn btn-primary">Next event</button>
        </div>
      </div>
      """
    end
  end

  @impl true
  def handle_event("navigate_to_next_event", %{"event" => event}, socket) do
    assigns = Map.put(socket.assigns, :event_number, String.to_integer(event) + 1)
    socket = assign_event(socket, assigns, :forward)

    {:noreply, socket}
  end

  @impl true
  def handle_event("navigate_to_previous_event", %{"event" => event}, socket) do
    assigns = Map.put(socket.assigns, :event_number, String.to_integer(event) - 1)
    socket = assign_event(socket, assigns, :backward)

    {:noreply, socket}
  end

  @impl true
  def handle_event("close", _params, socket) do
    return_to = socket.assigns.return_to

    {:noreply, push_patch(socket, to: return_to)}
  end

  defp assign_event(socket, assigns, read_stream_direction \\ :forward) do
    %{
      node: node,
      event_store: event_store,
      event_number: event_number,
      return_to: return_to,
      stream_uuid: stream_uuid
    } = assigns

    with {:ok, event} <-
           read_event(node, event_store, read_stream_direction, stream_uuid, event_number) do
      assign(socket,
        node: node,
        event_store: event_store,
        stream_uuid: stream_uuid,
        return_to: return_to,
        event: event,
        inspect_opts: [limit: :infinity, printable_limit: :infinity, pretty: true],
        return_to: return_to,
        error: nil
      )
    else
      {:error, :event_not_found} ->
        assign(socket, error: "Event not found", event: nil, event_number: event_number)

      {:error, error} ->
        assign(socket, error: inspect(error), event: nil, event_number: event_number)
    end
  end

  defp read_event(node, event_store, direction, stream_uuid, event_number) do
    read_stream_function =
      case direction do
        :backward -> :read_stream_backward
        :forward -> :read_stream_forward
      end

    case rpc_event_store(node, event_store, read_stream_function, [stream_uuid, event_number, 1]) do
      {:ok, [recorded_event]} -> {:ok, recorded_event}
      {:ok, []} -> {:error, :event_not_found}
      {:error, _error} = reply -> reply
    end
  end
end
