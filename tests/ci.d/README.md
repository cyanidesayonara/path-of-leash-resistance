# tests/ci.d

More lines of CI's test list, read after `tests/ci_tests.txt` by
`tools/run_tests.sh`, in file-name order. A walk's or a feature's new tests go
in a file of its own here (`WALK_ID.txt`, `FEATURE.txt`), in the same format:
one test per line, written as in `tests/ci_tests.txt` (the editor's arguments,
`--headless --path . --script res://tests/test_NAME.gd`), `# cost N` above one that takes 10 s or
more on CI, `#` comments and blank lines ignored. Two PRs side by side then
add their tests to two files, not the same end of one list.
