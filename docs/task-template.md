# Task Template

Copy this into a new issue or task description before starting work.

## Title

<Short imperative title>

## Context

- Which doc(s) describe this feature: `docs/____.md`
- Related existing code: `client/____`, `server/____`

## Scope

- [ ] In scope: ...
- [ ] Out of scope: ...

## Acceptance criteria

- [ ] Criterion 1 (testable)
- [ ] Criterion 2 (testable)

## Test plan

- [ ] `mvn test` passes (server)
- [ ] Headless Godot test passes (client), if applicable
- [ ] Manual smoke test: login → move → see broadcast

## Notes for the agent

- Start from the smallest vertical slice.
- If protocol changes, regenerate bindings first.
- Update docs if the implementation deviates from the design.
