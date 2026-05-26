Output docs/demo-evidence/STORY-014/AC-full-test-suite.gif
Output docs/demo-evidence/STORY-014/AC-full-test-suite.webm

Require bats

Set Shell "zsh"
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
Type "cd /Users/jmagady/Dev/brain-factory/.worktrees/STORY-014"
Enter
Sleep 1s
Type "clear"
Enter
Sleep 500ms
Show

# Full bats test suite: hook-event-emit.bats + meta-lint.bats — all 20 tests pass
Type "bats plugins/brain-factory/tests/hook-event-emit.bats plugins/brain-factory/tests/meta-lint.bats"
Enter
Sleep 30s
