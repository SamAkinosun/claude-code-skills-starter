---
name: test-writer
description: Use this skill when the user asks to write tests, add a missing test, or improve test coverage for a specific function or file. Reads the surrounding tests first to match style; does not invent a test framework if the project does not already use one.
---

# test-writer

When this skill triggers:

1. Identify the test target. The user usually points at a function or file. If the prompt is vague ("write tests for this"), ask which file or function and stop until they answer.

2. Locate existing tests in the same project:
   - Look for `tests/`, `test/`, `__tests__/`, or `*.test.*` files near the target.
   - If none exist, ask the user which framework to use. Do not assume `pytest`, `jest`, `vitest`, or anything else without checking.

3. Read 2-3 existing tests in the same project to match:
   - File naming convention (e.g., `test_<name>.py` vs `<name>.test.ts`)
   - Class-based vs function-based structure
   - Assertion style (e.g., `assertEqual` vs `assert ==`, `expect().toBe()` vs `expect.equal()`)
   - How fixtures or mocks are constructed
   - What level of integration is the norm (unit-only vs hits-real-DB)

4. Write the test in a new file or as additions to an existing one. For each test case:
   - One behavior per test, named after the behavior, not the function
   - Arrange / act / assert structure, but without writing those headers as comments
   - Cover at least one happy path, one edge case, one error case
   - Use the project's existing fixtures and mocks; do not introduce new test deps

5. Run the test suite to confirm the new tests pass and the existing ones still pass. Report counts.

## Style rules

- Test names describe behavior: `test_returns_zero_for_empty_input`, not `test_calculate`
- One assertion per test where reasonable; multiple is fine if they all check facets of the same behavior
- Avoid setUp / beforeEach for shared state if it makes tests harder to read in isolation
- Mock the smallest reasonable boundary; do not mock the function under test

## Anti-patterns

- Don't write a test that just re-runs the implementation. If `add(2, 3)` is "return a + b", do not write `assert add(2, 3) == 2 + 3`.
- Don't add a new test framework or runner.
- Don't add a snapshot test unless the project already uses snapshot testing.
- Don't write tests that depend on wall-clock time or environment-specific paths.

## When to push back

- If the function has high cyclomatic complexity, suggest refactoring before writing the test rather than writing 12 cases for branches that should not exist.
- If the function reaches into the network or filesystem and the project has no fixture pattern, propose making the dependency injectable rather than adding a new mock library.
