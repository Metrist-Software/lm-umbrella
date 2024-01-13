# LmAgent Statsd Server

## Compatibility

This agent currently should be compatible with DogStatsd or Statsd clients. 

deleteGauges, deleteCounters, deleteHistograms, etc. configuration options are currently not supported. Those options are supported by the Etsy statsd server and other servers such as Netdata's but in our case we send 0's for most metric types or the last value for gauges if we don't receive anything during a flush window. This is the default behaviour
for the Statsd and Netdata servers.

See metric modules for more precise descriptions for those modules.

Tags are supported as defined by the Dogstatsd format

## Supported Metric Types

- counters
- timers
- meters
- gauges
- histograms
- sets
- dictionaries

## Testing

To enable the server, ensure your environment has `LM_STATSD_ENABLED` set to `true` and run the agent.

By default, the flush interval is 10s and the port is udp port 8125.

The tests are included as normal ExUnit tests. To run them run

`mix test` from the agent directory or `mix cmd --app lm_agent mix test --color` from the root

To run a random set of statsd events against the server, start the server then run

`bash test/data/statsd-test.sh` from the agent directory or `bash apps/lm_agent/test/data/statsd-test.sh` from the root