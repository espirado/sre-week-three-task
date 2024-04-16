#!/bin/bash

# Define variables
NAMESPACE="sre"
DEPLOYMENT_NAME="swype-app"
MAX_RESTARTS=3

# Infinite loop to monitor pod restarts
while true; do
    # Get pods by deployment
    pods=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME -o jsonpath="{.items[*].metadata.name}")

    for pod in $pods; do
        # Fetch the restart count for each pod
        restart_count=$(kubectl get pod $pod -n $NAMESPACE -o jsonpath="{.status.containerStatuses[0].restartCount}")

        # Validate the fetched restart count
        if ! [[ "$restart_count" =~ ^[0-9]+$ ]]; then
            echo "Failed to fetch a valid restart count for $pod. Assuming 0 restarts."
            restart_count=0
        fi

        # Output the current number of restarts
        echo "Pod $pod has restarted $restart_count times."

        # Check if restarts exceed the maximum allowed number
        if [ "$restart_count" -gt $MAX_RESTARTS ]; then
            echo "Pod $pod exceeded max restarts. Taking appropriate action..."
            kubectl scale deployment $DEPLOYMENT_NAME --replicas=0 -n $NAMESPACE
            # This break will exit the for-loop and the while-loop should also be terminated
            break 2  # Correct usage of break 2 to exit both loops
        fi
    done

    # Wait for some time before the next check
    sleep 60
done
