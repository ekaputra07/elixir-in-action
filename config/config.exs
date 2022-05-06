import Config

config :todo,
  http_port: 4000,
  db_folder: "./persist",
  db_num_workers: 3

import_config "#{config_env()}.exs"
