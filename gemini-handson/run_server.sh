#!/bin/bash

cd ./faiss_web

PID_FILE="faiss_web.pid"
LOG_FILE="faiss_web.log"

if [ -f "$PID_FILE" ]; then
    PID=$(cat $PID_FILE)
    echo "Existing PID found: $PID. Attempting to kill..."

    PIDS=$(ps -ef | grep -E 'gradio|faiss_web.py|frpc|42001' | grep -v grep | awk '{print $2}')

    for PID in $PIDS; do
        pkill -P $PID
        kill $PID
        echo "   Process $PID to kill..."
    done

    if [ $? -eq 0 ]; then
        echo "   Process $PID killed successfully."
        rm $PID_FILE
    else
        echo "   Failed to kill process $PID. Check manually."
        exit 1
    fi

    sleep 2
fi

nohup gradio faiss_web.py 1> $LOG_FILE 2>&1 &
echo $! > $PID_FILE

echo "Gradio is starting... Logging to $LOG_FILE"
sleep 1
{
    timeout 20 tail -f $LOG_FILE | grep -m 1 "Running on public URL"
    if [ $? -eq 124 ]; then
        echo "Timeout reached without finding the URL."
    fi
}

echo "Gradio started with PID $(cat $PID_FILE)."
