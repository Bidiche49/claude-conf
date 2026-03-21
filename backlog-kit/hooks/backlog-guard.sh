#!/bin/bash
# ── backlog-guard — PreToolUse Write hook ──────────────────────────
# Blocks creation of BACKLOG/ tickets with duplicate IDs.
# Reads tool_input JSON from stdin, checks for ID conflicts.
#
# Exit codes:
#   0 — allowed (not a BACKLOG write, or ID is free)
#   2 — blocked (duplicate ID)

set -e

# Read input JSON from stdin
input="$(cat)"

# Extract file_path from tool_input
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty')"

# No file_path → not our concern
if [ -z "$file_path" ]; then
    exit 0
fi

# Check if path targets BACKLOG/ (absolute or relative)
case "$file_path" in
    */BACKLOG/*) ;;
    BACKLOG/*)   ;;
    *)           exit 0 ;;
esac

# Extract the filename (e.g., BUG-005.md)
filename="$(basename "$file_path")"

# Extract type prefix and ID number (e.g., BUG-005 → type=BUG, id=005)
if [[ "$filename" =~ ^(BUG|FEAT|IMP)-([0-9]+)\.md$ ]]; then
    ticket_type="${BASH_REMATCH[1]}"
    ticket_id="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
else
    # Not a ticket file (e.g., INDEX.md, _templates/) → allow
    exit 0
fi

# Map ticket type to directory name
case "$ticket_type" in
    BUG)  type_dir="BUGS" ;;
    FEAT) type_dir="FEATURES" ;;
    IMP)  type_dir="IMPROVEMENTS" ;;
    *)    exit 0 ;;
esac

# Find the BACKLOG root from the file_path
# Strip everything after BACKLOG/ to get the base
backlog_root="${file_path%%/BACKLOG/*}/BACKLOG"
if [ "$backlog_root" = "$file_path" ]; then
    # Relative path case: BACKLOG/...
    backlog_root="BACKLOG"
fi

# Scan PENDING/ and DONE/ for existing files with this ID
pending_dir="$backlog_root/$type_dir/PENDING"
done_dir="$backlog_root/$type_dir/DONE"

found=""
if [ -f "$pending_dir/$filename" ]; then
    found="$pending_dir/$filename"
elif [ -f "$done_dir/$filename" ]; then
    found="$done_dir/$filename"
fi

if [ -n "$found" ]; then
    # Find next available ID
    max_num=0
    for f in "$pending_dir/${ticket_type}"-*.md "$done_dir/${ticket_type}"-*.md; do
        [ -f "$f" ] || continue
        base="$(basename "$f" .md)"
        num="${base#"${ticket_type}"-}"
        # Remove leading zeros for arithmetic
        num=$((10#$num))
        if [ "$num" -gt "$max_num" ]; then
            max_num="$num"
        fi
    done
    next_num=$((max_num + 1))
    next_id=$(printf "%s-%03d" "$ticket_type" "$next_num")

    echo "BLOCKED: $ticket_id already exists at $found. Next available: $next_id"
    exit 2
fi

exit 0
