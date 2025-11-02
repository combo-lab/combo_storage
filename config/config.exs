import Config

config :waffle,
  storage: Combo.Storage.Adapters.S3

config :ex_aws,
  json_codec: Jason
