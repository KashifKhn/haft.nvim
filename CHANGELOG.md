# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup
- Documentation (README.md, CONTRIBUTING.md, AGENTS.md)
- Vimdoc (doc/haft.txt)

### Planned
- Phase 1: Foundation (config, health, detection, runner, parser)
- Phase 2: UI Components (float, notify, input)
- Phase 3: Generation Commands
- Phase 4: Telescope Pickers
- Phase 5: Terminal & Dev Commands
- Phase 6: Polish & Events
- Phase 7: Testing & Documentation

---

## Version History

### [1.0.0] - TBD

#### Added
- Full integration with Haft CLI commands
- Project information commands (`:HaftInfo`, `:HaftRoutes`, `:HaftStats`)
- Dependency management (`:HaftAdd`, `:HaftRemove`)
- Code generation commands
  - `:HaftGenerate` - Component type picker
  - `:HaftGenerateResource` - Full CRUD resource
  - `:HaftGenerateController` - REST controller
  - `:HaftGenerateService` - Service layer
  - `:HaftGenerateRepository` - JPA repository
  - `:HaftGenerateEntity` - JPA entity
  - `:HaftGenerateDto` - Request/Response DTOs
  - `:HaftGenerateException` - Exception handler
  - `:HaftGenerateConfig` - Config classes
  - `:HaftGenerateSecurity` - Security setup
- Development commands
  - `:HaftDevBuild` - Build project
  - `:HaftDevTest` - Run tests
  - `:HaftDevServe` - Start dev server
  - `:HaftDevRestart` - Trigger restart
  - `:HaftDevClean` - Clean artifacts
  - `:HaftDevToggle` - Toggle terminal
- Telescope extension with pickers
- Floating window displays
- Terminal management
- User autocommand events
- Health check (`:checkhealth haft`)
- Full configuration system
- Lua API for programmatic access

---

## Release Notes Template

When releasing a new version, copy this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes
```

---

[Unreleased]: https://github.com/KashifKhn/haft.nvim/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/KashifKhn/haft.nvim/releases/tag/v1.0.0
