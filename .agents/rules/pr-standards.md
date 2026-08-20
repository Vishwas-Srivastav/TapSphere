# Pull Request & Engineering Standards — TapSphere

1. **Branch Naming**: Cut from `development` using `<PROJECT_INITIALS>-<NUMBER>` (e.g., `TS-01`, `TS-02`).
2. **Commit & PR Title Format**: [Conventional Commits](https://www.conventionalcommits.org/) (`feat: ...`, `fix: ...`, `chore: ...`).
3. **PR Description Template**: Must include `## Summary`, `## Why`, `## Testing`, `## Related Work`, and checked `Checklist`.
4. **Verification**: Pre-push execution of `./scripts/check-guardrails.sh` and `./scripts/build.sh`.
