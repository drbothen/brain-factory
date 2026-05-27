# AC-010 — block-ai-attribution.sh: clean bash command exits 0
# Traces to BC-2.04.012 postconditions on no tokens: 1
# Success path: git commit with no attribution tokens -> exit 0

Output docs/demo-evidence/STORY-012/AC-010-attribution-clean-allow.gif
Output docs/demo-evidence/STORY-012/AC-010-attribution-clean-allow.webm

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

Type "# AC-010: clean git commit passes attribution hook -> exit 0"
Enter
Sleep 500ms
Type "bash docs/demo-evidence/STORY-012/scripts/demo-ac010.sh"
Enter
Sleep 3s

Sleep 2s
