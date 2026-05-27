# AC-005 — enforce-kebab-case.sh: CLAUDE.md is exempt from kebab-case check -> exit 0
# Traces to BC-2.04.011 invariant 3; edge case EC-001

Output docs/demo-evidence/STORY-012/AC-005-exempt-claude-md.gif
Output docs/demo-evidence/STORY-012/AC-005-exempt-claude-md.webm

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

Type "# AC-005: CLAUDE.md is on the exception list -> exit 0"
Enter
Sleep 500ms
Type "bash docs/demo-evidence/STORY-012/scripts/demo-ac005.sh"
Enter
Sleep 3s

Sleep 2s
