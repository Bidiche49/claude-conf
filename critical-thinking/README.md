# critical-thinking

Anti-complacency module for Claude Code. Turns Claude into a sparring partner that challenges ideas instead of validating by default.

- Classification system: Solide / Discutable / Simplifie / Angle mort / Faux
- 5 anti-complacency reflexes (stress-test, hold position, detect errors, iterate, self-diagnose)
- 3-validation rule: 3 consecutive approvals triggers active fault-finding
- Calibration by decision level (architecture = max challenge, style = light)

## Install

```bash
bash install.sh
```

## Dependencies

- Claude Code

## Works best with

- `supervisor` — gets a CTO POSTURE block injected automatically

## What it does

1. Injects anti-complacency rules into `~/.claude/CLAUDE.md`
2. Replaces the "stagiaire" framing with "associe technique"
3. Patches `supervisor.md` (local copy) with a CTO POSTURE block (if installed)
