#!/bin/bash

# Read the JSON input from stdin
input=$(cat)

# Get session data
transcript_path=$(echo "$input" | jq -r '.transcript_path')
model_id=$(echo "$input" | jq -r '.model.id')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Calculate session start time from transcript file creation time
current_time=$(date +%s)
if [[ -f "$transcript_path" ]]; then
    # Get file creation time (birth time on macOS)
    session_start=$(stat -f %B "$transcript_path" 2>/dev/null || stat -c %Y "$transcript_path" 2>/dev/null || echo "$current_time")
else
    # Fallback: use current time (session just started)
    session_start=$current_time
fi
elapsed_seconds=$((current_time - session_start))

# Ensure elapsed time is not negative (safety check)
if [[ $elapsed_seconds -lt 0 ]]; then
    elapsed_seconds=0
fi

# Format elapsed time as HH:MM:SS
elapsed_hours=$((elapsed_seconds / 3600))
elapsed_minutes=$(((elapsed_seconds % 3600) / 60))
elapsed_secs=$((elapsed_seconds % 60))
elapsed_formatted=$(printf "%02d:%02d:%02d" $elapsed_hours $elapsed_minutes $elapsed_secs)

# Get actual token count from ccusage
if [[ -n "$session_id" ]] && command -v ccusage >/dev/null 2>&1; then
    # Get only the last entry's tokens (they're cumulative)
    session_tokens=$(ccusage session --id "$session_id" --json --jq '.entries[-1] | (.inputTokens + .outputTokens + .cacheReadTokens)' 2>/dev/null)
    
    if [[ -n "$session_tokens" ]] && [[ "$session_tokens" =~ ^[0-9]+$ ]] && [[ "$session_tokens" -gt 0 ]]; then
        estimated_tokens=$session_tokens
        
        # Calculate percentage of context window
        if [[ "$model_id" == *"opus"* ]]; then
            context_window=200000
        elif [[ "$model_id" == *"sonnet-4"* ]]; then
            context_window=200000
        else
            context_window=100000  # Conservative default
        fi
        
        context_percentage=$((estimated_tokens * 100 / context_window))
        # Don't cap at 100% since compactions can make total exceed context window
    else
        # Set all to err if ccusage fails
        estimated_tokens="err"
        context_window="err" 
        context_percentage="err"
    fi
else
    estimated_tokens="err"
    context_window="err"
    context_percentage="err"
fi

# Test and get ccusage output
ccusage_output=""
if command -v ccusage >/dev/null 2>&1; then
    # Pass the JSON input to ccusage statusline
    ccusage_test=$(echo "$input" | ccusage statusline 2>&1)
    if [[ $? -eq 0 ]] && [[ -n "$ccusage_test" ]] && [[ "$ccusage_test" != *"error"* ]] && [[ "$ccusage_test" != *"Error"* ]]; then
        ccusage_output="$ccusage_test"
    fi
fi

# Build status line
status_parts=()

# Add ccusage if available and working
if [[ -n "$ccusage_output" ]]; then
    status_parts+=("$ccusage_output")
fi

# Add working metrics
status_parts+=("🕐 ${elapsed_formatted}")
if [[ "$context_percentage" == "err" ]]; then
    status_parts+=("🧠 err")
else
    status_parts+=("🧠 ${estimated_tokens}/${context_window} (${context_percentage}%)")
fi

# Join with separator
printf "%s" "$(IFS=' │ '; echo "${status_parts[*]}")"