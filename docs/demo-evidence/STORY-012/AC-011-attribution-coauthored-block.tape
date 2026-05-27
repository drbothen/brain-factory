# AC-011 — block-ai-attribution.sh: Co-Authored-By: Claude token exits 2 + E-ATTR-001
# Traces to BC-2.04.012 postconditions on token found: 1-2; invariant 1
# Error path: command containing Co-Authored-By: Claude Opus -> exit 2

Output docs/demo-evidence/STORY-012/AC-011-attribution-coauthored-block.gif
Output docs/demo-evidence/STORY-012/AC-011-attribution-coauthored-block.webm

Require bash

Set Shell "bash"
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 20
Set Width 1200
Set Height 600
Set Theme "Catppuccin Mocha"
Set WindowBar Colorful
Set BorderRadius 8
Set Padding 20
Set Framerate 30
Set TypingSpeed 50ms

Hide
Type "PS1='$ '"
Enter
Sleep 1s
Type "cd /Users/jmagady/Dev/brain-factory/.worktrees/STORY-012"
Enter
Sleep 1s
Type "clear"
Enter
Sleep 1s
Show

Type "# AC-011: Co-Authored-By: Claude Opus is blocked -> exit 2 + E-ATTR-001"
Enter
Sleep 500ms
Type "bash docs/demo-evidence/STORY-012/scripts/demo-ac011.sh"
Enter
Sleep 3s

Sleep 2s
