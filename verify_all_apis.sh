#!/bin/bash
# API Verification Script - Check All Endpoints
# Tests: Predict, Compatibility, Feedback, History

API_KEY="astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic"
BASE_URL="http://localhost:8000"
USER_EMAIL="prabhukushwaha@gmail.com"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║             API VERIFICATION RUN                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. PREDICT API
echo "----------------------------------------------------------------"
echo "1. TESTING PREDICT API..."
echo "----------------------------------------------------------------"
PREDICT_RESP=$(curl -s -X POST "$BASE_URL/vedic/api/predict/" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: $API_KEY" \
  -d '{
    "query": "How is my career?",
    "birth_data": {
      "dob": "1994-07-01",
      "time": "00:15",
      "latitude": 18.4386,
      "longitude": 79.1288
    },
    "include_reasoning_trace": false,
    "user_email": "'$USER_EMAIL'"
  }')

echo "$PREDICT_RESP" | jq '.' > predict_response.json
echo "✅ Response Saved."
PRED_ID=$(echo "$PREDICT_RESP" | jq -r '.prediction_id')
USER_ID=$(echo "$PREDICT_RESP" | jq -r '.user_id // "prabhukushwaha@gmail.com"') # Fallback if not returned
echo "Prediction ID: $PRED_ID"
echo ""

# 2. COMPATIBILITY API
echo "----------------------------------------------------------------"
echo "2. TESTING COMPATIBILITY API..."
echo "----------------------------------------------------------------"
COMPAT_RESP=$(curl -s -X POST "$BASE_URL/vedic/api/compatibility/analyze" \
  -H "Content-Type: application/json" \
  -H "X-API-KEY: $API_KEY" \
  -d '{
    "boy": {"dob": "1994-07-01", "time": "00:15", "lat": 18.4386, "lon": 79.1288, "name": "Boy"},
    "girl": {"dob": "1996-04-20", "time": "04:45", "lat": 34.0522, "lon": -118.2437, "name": "Girl"},
    "user_email": "'$USER_EMAIL'"
  }')

echo "$COMPAT_RESP" | jq '.' > compatibility_response.json
echo "✅ Response Saved."
echo ""

# 3. FEEDBACK API
echo "----------------------------------------------------------------"
echo "3. TESTING FEEDBACK API..."
echo "----------------------------------------------------------------"
if [ "$PRED_ID" != "null" ]; then
    FEEDBACK_RESP=$(curl -s -X POST "$BASE_URL/feedback/submit" \
      -H "Content-Type: application/json" \
      -H "X-API-KEY: $API_KEY" \
      -d '{
        "prediction_id": "'$PRED_ID'",
        "rating": 5,
        "feedback_text": "Great accuracy!",
        "user_email": "'$USER_EMAIL'"
      }')
    
    echo "$FEEDBACK_RESP" | jq '.' > feedback_response.json
    echo "✅ Response Saved."
else
    echo "⚠️ Skipping Feedback (No prediction ID)"
fi
echo ""

# 4. CHAT HISTORY API
echo "----------------------------------------------------------------"
echo "4. TESTING CHAT HISTORY (THREADS)..."
echo "----------------------------------------------------------------"
HISTORY_RESP=$(curl -s -X GET "$BASE_URL/chat-history/threads/$USER_EMAIL" \
  -H "X-API-KEY: $API_KEY")

echo "$HISTORY_RESP" | jq '.' > history_response.json
echo "✅ Response Saved."
THREAD_COUNT=$(echo "$HISTORY_RESP" | jq '.threads | length')
echo "Threads Found: $THREAD_COUNT"
echo ""

echo "----------------------------------------------------------------"
echo "DONE. Check .json files for details."
echo "----------------------------------------------------------------"
