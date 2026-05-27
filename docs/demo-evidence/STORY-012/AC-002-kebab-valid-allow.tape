# AC-002 — enforce-kebab-case.sh: valid kebab-case filename exits 0
# Traces to BC-2.04.011 postconditions on kebab-case; EC-004
# Success path: wiki/concepts/ai-agents.md -> exit 0, verdict allow

Output docs/demo-evidence/STORY-012/AC-002-kebab-valid-allow.gif
Output docs/demo-evidence/STORY-012/AC-002-kebab-valid-allow.webm

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

Type "# AC-002: valid kebab-case filename -> exit 0"
Enter
Sleep 500ms
Type "bash docs/demo-evidence/STORY-012/scripts/demo-ac002.sh"
Enter
Sleep 3s

Sleep 2s
