# AC-003 — enforce-kebab-case.sh: non-kebab filename (space+uppercase) exits 2 + E-NAMING-001
# Traces to BC-2.04.011 postconditions on non-kebab: 1-3; edge case EC-002
# Error path: AI Agents.md -> exit 2, E-NAMING-001, suggestion ai-agents.md

Output docs/demo-evidence/STORY-012/AC-003-kebab-invalid-block.gif
Output docs/demo-evidence/STORY-012/AC-003-kebab-invalid-block.webm

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

Type "# AC-003: non-kebab (space+uppercase) -> exit 2 + E-NAMING-001"
Enter
Sleep 500ms
Type "bash docs/demo-evidence/STORY-012/scripts/demo-ac003.sh"
Enter
Sleep 3s

Sleep 2s
