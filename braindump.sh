#!/bin/bash
# 
# Braindump
#
# (c) 2019 Jason Charcalla
#
# Parses output from the ThinkGear Connect software using netcat
# and sends to a promethues endpoint.

print_usage() {
        echo "Usage: $PROGNAME "
	no option: JSON to STDOUT
        -f Write to file for node_exporter to watch.
        -p Send metrics to Prometheus push gateway.
       exit 1
}

break_loop() {
	echo "$(date) - braindump: <ctrl-c> detected. exiting!"
	# Kill the data capture process so we can start it again
	kill ${NC_OUTPUT_PID}

	exit 0	
}


while getopts h?f:p arg ; do
      case $arg in
        p) MODE="push" ;;
        f) MODE="file" ;;
        h|\?) print_usage; exit ;;
      esac
done

# Raw files will rotate after # of eSense data. Approx 10 MB each.
RAW_LINES=1000
RAW_LOG_FILE_PREFIX=rawlog_braindump-
PROMETHEUS_URL=http://192.168.0.1:9091/metrics/job/braindump/subject/person

stream_capture(){
	while read line ;
	do
	    if echo ${line} | grep -q "eSense"
  	    then
		#echo ${line}
        	# Parse lines into variables with some extra filter to delete extranious characters.
        	ATTENTION=$(echo "${line}" | sed 's/.*\"attention\"://' | cut -d "," -f1)
        	MEDITATION=$(echo "${line}" | sed 's/.*\"meditation\"://' | cut -d "," -f1 | tr -d '{},')
       		DELTA=$(echo "${line}" | sed 's/.*\"delta\"://' | cut -d "," -f1 | tr -d '{},')
        	THETA=$(echo "${line}" | sed 's/.*\"theta\"://' | cut -d "," -f1 | tr -d '{},')
        	LOWALPHA=$(echo "${line}" | sed 's/.*\"lowAlpha\"://' | cut -d "," -f1 | tr -d '{},')
        	HIGHALPHA=$(echo "${line}" | sed 's/.*\"highAlpha\"://' | cut -d "," -f1 | tr -d '{},')
        	HIGHBETA=$(echo "${line}" | sed 's/.*\"highBeta\"://' | cut -d "," -f1 | tr -d '{},')
        	LOWBETA=$(echo "${line}" | sed 's/.*\"lowBeta\"://' | cut -d "," -f1 | tr -d '{},')
        	LOWGAMA=$(echo "${line}" | sed 's/.*\"lowGamma\"://' | cut -d "," -f1 | tr -d '{},')
        	HIGHGAMA=$(echo "${line}" | sed 's/.*\"highGamma\"://' | cut -d "," -f1 | tr -d '{},')
        	POORSIGNAL=$(echo "${line}" | sed 's/.*\"poorSignalLevel\"://' | cut -d "," -f1 | tr -d '{},')

		# Prometheus push gateway mode
		if [ "${MODE}" == "push" ]
		then
		   
 		   cat <<EOF | curl --data-binary @- ${PROMETHEUS_URL}
# TYPE eeg_attention gauge
eeg_attention ${ATTENTION}
# TYPE eeg_meditation gauge
eeg_meditation ${MEDITATION}
# TYPE eeg_delta gauge
eeg_delta ${DELTA}
# TYPE eeg_theta gauge
eeg_theta ${THETA}
# TYPE eeg_lowalpha gauge
eeg_lowalpha ${LOWALPHA}
# TYPE eeg_highalpha gauge
eeg_highalpha ${HIGHALPHA}
# TYPE eeg_highbeta gauge
eeg_highbeta ${HIGHBETA}
# TYPE eeg_lowbeta gauge
eeg_lowbeta ${LOWBETA}
# TYPE eeg_lowgama gauge
eeg_lowgama ${LOWGAMA}
# TYPE eeg_highgama gauge
eeg_highgama ${HIGHGAMA}
# TYPE eeg_poorsignal gauge
eeg_poorsignal ${POORSIGNAL}
EOF

		# Prometheus node_exporter file mode
		elif [ "${MODE}" == "file" ]
		then
		   echo "$(date) - braindump: Node exporter file mode not implimented yet."

		# Influxdb mode
		elif [ "${MODE}" == "influxdb" ]
		then
		   echo "$(date) - braindump: InfluxDB mode not implimented yet."
		else
		#echo "$(date) - braindump: No flag selected, outputing to std out."
		echo "${line}"
		fi

		LINE_COUNT=$(($LINE_COUNT + 1 ))
		if [ ${LINE_COUNT} -eq ${RAW_LINES} ]
		then
			break
		fi		
	  fi
	done< <(exec tail -fn0 ${RAW_OUTPUT})
}


# write samples to a file, limit to 1000 and then start a new file. run this as a background.
echo "$(date) - braindump: Use <ctrl-c> to exit. If raw file size does not increase then capture is not sucssesful."

# 
# trap <ctrl-c> for to allow graceful exit
#
trap 'break_loop' SIGINT

while true
do
	RAW_OUTPUT=${RAW_LOG_FILE_PREFIX}-$(date +%Y%m%d%H%M%S).log
	LINE_COUNT=0

	# Capture data from tcp socket
	echo "$(date) - braindump: Capturing raw data to file $(pwd)/${RAW_OUTPUT}."
	nc -d localhost 13854 | tr -c [:print:] '\n' > ${RAW_OUTPUT} &
	NC_OUTPUT_PID=$!

	# Run function that reads file via tail, exits after 1000
	stream_capture

	# Kill the data capture process so we can start it again
	kill ${NC_OUTPUT_PID}

	# Sleep, just in case something goes wrong we wont run away to fast
	sleep 1
done


exit 0
