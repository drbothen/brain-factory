# AC-SUITE — Full bats suites: 26 tests for enforce-kebab-case, 17 for block-ai-attribution
# Covers VP-017 verification evidence for both hooks

Output docs/demo-evidence/STORY-012/AC-SUITE-bats-all-green.gif
Output docs/demo-evidence/STORY-012/AC-SUITE-bats-all-green.webm

Require bats

Set Shell "bash"
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 20
Set Width 1200
Set Height 700
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

Type "# enforce-kebab-case: 26 tests"
Enter
Sleep 500ms
Type "bats plugins/brain-factory/tests/enforce-kebab-case.bats --tap"
Enter
Sleep 15s

Type "# block-ai-attribution: 17 tests"
Enter
Sleep 500ms
Type "bats plugins/brain-factory/tests/block-ai-attribution.bats --tap"
Enter
Sleep 10s

Sleep 2s
