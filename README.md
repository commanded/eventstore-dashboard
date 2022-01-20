# EventStore Dashboard

EventStore Dashboard is a tool to analyze [`EventStore`](https://hexdocs.pm/eventstore) databases. It provides access to events, streams, snapshots, and subscriptions.

It works as an additional page for the [`Phoenix LiveDashboard`](https://hexdocs.pm/phoenix_live_dashboard).

![eventstore-dashboard-streams](https://user-images.githubusercontent.com/3167/150383255-eb9005a1-53f6-4c1e-9ef7-4534238ffa3c.png)

![eventstore-dashboard-stream-events](https://user-images.githubusercontent.com/3167/150383321-4062cdf3-c820-4ef1-95ca-bc06cd3dfd31.png)

![eventstore-dashboard-event](https://user-images.githubusercontent.com/3167/150383355-2f3a2e71-b3c5-495f-a79e-398b2f693c98.png)

## Integration with Phoenix LiveDashboard

You can add this page to your Phoenix LiveDashboard by adding as a page in the `live_dashboard` macro at your router file.

```elixir
live_dashboard "/dashboard",
  additional_pages: [
    eventstores: {EventStore.Dashboard, event_stores: [MyEventStore]}
  ]
```

The `:event_stores` option accept event store names (the `:name` option of your EventStore). By omitting the `:event_stores` option, EventStore Dashboard will try to auto discover your event stores.

```elixir
live_dashboard "/dashboard",
  additional_pages: [
    eventstores: EventStore.Dashboard
  ]
```

Once configured, you will be able to access the EventStore Dashboard at `/dashboard/eventstore`.

## Installation

Add the following to your `mix.exs` and run mix `deps.get`:

```elixir
def deps do
  [
    {:eventstore_dashboard, github: "commanded/eventstore-dashboard"}
  ]
end
```

After that, proceed with instructions described in **Integration with Phoenix LiveDashboard** above.

### Known limitations

* Dynamic event stores are not currently supported.
* Subscriptions and snapshots have not yet been implemented.

## Contributing

For those planning to contribute to this project, you can run a dev version of the dashboard with the following commands:

    $ mix setup
    $ mix dev

Alternatively, run `iex -S mix dev [flags]` if you also want a shell.

## Acknowledgment

This project is based on the [Broadway Dashboard](https://github.com/dashbitco/broadway_dashboard) tool which is used to analyse [Broadway](https://hex.pm/packages/broadway) pipelines. Thank you to the entire Dashbit team for their inspiration! It also builds upon the excellent [Phoenix LiveDashboard](https://github.com/phoenixframework/phoenix_live_dashboard) project, thank you to the Phoenix framework team.
