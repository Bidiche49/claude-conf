#!/bin/bash
# Hook SessionStart — Re-applies tab/window title after Claude Code startup
# Fixes: title overwritten by Ink framework terminal initialization
#
# Reads CC_TAB_TITLE and CC_WIN_TITLE env vars set by the zsh launcher functions

# Skip if module is disabled
grep -q "^tab-titles$" "$HOME/.claude-conf-disabled" 2>/dev/null && exit 0

# Read (and discard) stdin — hooks must consume their input
cat > /dev/null

# Re-apply titles from env vars (set by cc/ccd/ccs/ccw functions)
if [ -n "$CC_TAB_TITLE" ]; then
    printf "\033]1;%s\007" "$CC_TAB_TITLE" > /dev/tty 2>/dev/null
fi

if [ -n "$CC_WIN_TITLE" ]; then
    printf "\033]2;%s\007" "$CC_WIN_TITLE" > /dev/tty 2>/dev/null
fi

exit 0
