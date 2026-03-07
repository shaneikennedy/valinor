#!/bin/bash

for i in $(seq 1 10); do
  code=$(curl -s -o /dev/null -w "%{http_code}" -H "x-user-id: 5" http://localhost:3000/)
  echo "Request $i: HTTP $code"
  sleep 0.5
done
