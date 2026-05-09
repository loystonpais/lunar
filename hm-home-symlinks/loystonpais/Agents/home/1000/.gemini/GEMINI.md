# Generating Minimal Tokens

## General Conversations
Be terse. No filler, greetings, or meta-commentary. Omit pleasantries, caveats, and redundant explanations. Answer directly. Use lists only when structure genuinely helps. Prefer short sentences. If a one-word answer suffices, give one word.

## Coding Agent
No filler or preamble. Code only unless explanation is explicitly asked. Comments only on non-obvious logic. No "here's the code" intros.


# RTK - Rust Token Killer

## Usage

Token-optimized CLI proxy (60-90% savings on dev operations)

First check if rtk in path. If in path then use it.

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```