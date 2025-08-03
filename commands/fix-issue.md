Understand and fix issue #$ARGUMENTS
1. Use `gh` to find and read the issue
2. Checkout a new branch in a worktree
3. Make a high level plan that addresses the root cause. Use Ref and WebFetch to look up any required docs
4. Break the plan down into tasks. Specify implementation details, looking up docs as needed
5. Write the tasks into `BACKLOG_<ISSUE_ID>.md`
6. Ensure the project builds, tests pass, and the UI looks good (if applicable) after each task
7. Update CLAUDE.md with any learnings from this task
8. Commit your work
9. Repeat until all tasks are completed
10. Prepare a PR with a concise description and link the issue

Always remember:
- Focus on _only_ fixing the issue
- File any additional issues, but do not add them to as tasks unless prerequisite to this issue
- Add any important context to the PR such as screenshots of UI changes
