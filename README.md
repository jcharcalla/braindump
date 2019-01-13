# Braindump

This script scrapes the socket created by the NeuroSky ThinkGear connector
program on OSX and forwards the data as metrics to a promethus pushgateway target.

![braindump metrics in grafana](images/braindump-grafana.png?raw=true)

## Prereques

1. NeuroSky headset (http://neurosky.com/biosensors/eeg-sensor/biosensors/)
2. NeuroSKy Thinkgear connector application. (https://store.neurosky.com/products/thinkgear-connector)
3. NeuroSky Vizualizer (https://store.neurosky.com/products/visualizer)
4. Prometheus pushgateway (https://prometheus.io/)

## Configuration.
1. Modify the `PROMETHEUS_URL=` variable in the `braindump.sh` script.

## Usage
1. Start Thinkgear connector.
2. Start NeuroSky Vizualizer to ensure connection, and initialize device.
3. `./braindump.sh -p`
