use Mix.Config

config :telemetry_event,
  init_server: true,
  add_poller: true,
  add_metrics: [:dead_letters_handled, :phoenix_endpoint_stop],
  metrics_options: [
    [
      metric_name: "dataset_compaction_duration_total.duration",
      tags: [:app, :system_name],
      metric_type: :sum
    ],
    [
      metric_name: "file_conversion_success.gauge",
      tags: [:app, :dataset_id, :file, :start],
      metric_type: :last_value
    ],
    [
      metric_name: "file_conversion_duration.gauge",
      tags: [:app, :dataset_id, :file, :start],
      metric_type: :last_value
    ],
    [
      metric_name: "dataset_record_total.count",
      tags: [:table_name],
      metric_type: :last_value
    ]
  ]
