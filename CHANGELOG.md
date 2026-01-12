# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - TBD

### Added

#### Core Infrastructure
- Full plugin architecture with modular design
- Configuration system with deep merging support
- Health check integration (`:checkhealth haft`)
- Project detection for Maven/Gradle/Haft projects
- Async CLI runner with plenary.job
- JSON response parser for CLI output

#### Project Initialization
- `:HaftInit` - Initialize new project with mode picker
- `:HaftInit tui` - TUI wizard mode (LazyGit-style)
- `:HaftInit wizard` - Neovim native wizard mode
- `:HaftInit <name>` - Quick create with given name
- `:HaftInitTui` - Direct TUI wizard
- `:HaftInitWizard` - Direct Neovim wizard
- `:HaftInitQuick [name]` - Quick create with defaults

#### Project Information
- `:HaftInfo` - Show project information in floating window
- `:HaftRoutes` - Show API routes in floating window
- `:HaftStats` - Show code statistics
- `:HaftStats cocomo` - Statistics with COCOMO cost estimates

#### Project Health
- `:HaftDoctor` - Run project health check
- `:HaftDoctor [category]` - Check specific category (build/source/config/security)
- `:HaftDoctor strict` - Strict mode (warnings as errors)

#### Dependency Management
- `:HaftAdd [dep...]` - Add dependencies (Telescope picker if no args)
- `:HaftRemove [dep...]` - Remove dependencies (Telescope picker if no args)
- Telescope pickers with category grouping and fuzzy search

#### Code Generation
- `:HaftGenerateResource [name]` - Generate complete CRUD resource
- `:HaftGenerateController [name]` - Generate REST controller
- `:HaftGenerateService [name]` - Generate service layer
- `:HaftGenerateRepository [name]` - Generate JPA repository
- `:HaftGenerateEntity [name]` - Generate JPA entity
- `:HaftGenerateDto [name]` - Generate Request/Response DTOs
- `:HaftGenerateException [all]` - Generate global exception handler
- `:HaftGenerateConfig [all]` - Generate configuration classes
- `:HaftGenerateSecurity [type]` - Generate security (jwt/session/oauth2/all)

#### Development Commands
- `:HaftServe` - Start dev server with hot-reload
- `:HaftServeStop` - Stop the dev server
- `:HaftServeToggle` - Toggle dev server terminal visibility
- `:HaftRestart` - Trigger restart of running dev server
- `:HaftBuild` - Build project
- `:HaftTest` - Run tests
- `:HaftClean` - Clean build artifacts
- `:HaftDeps` - Display dependency tree
- `:HaftOutdated` - Check for dependency updates

#### Auto-Restart Feature
- `:HaftAutoRestartEnable` - Enable auto-restart on file save
- `:HaftAutoRestartDisable` - Disable auto-restart
- `:HaftAutoRestartToggle` - Toggle auto-restart
- Configurable file patterns for restart triggers

#### Template Management
- `:HaftTemplateInit` - Initialize custom templates
- `:HaftTemplateInit [category]` - Initialize specific category
- `:HaftTemplateList` - List all available templates
- `:HaftTemplateValidate` - Validate templates for errors
- `:HaftTemplateValidate vars` - Show template variables

#### CLI Management
- `:HaftVersion` - Show Haft CLI version
- `:HaftUpgrade` - Upgrade to latest version
- `:HaftUpgrade check` - Check for updates
- `:HaftUpgrade force` - Force reinstall
- `:HaftUpgrade [version]` - Install specific version

#### UI Components
- Floating windows for info display
- Notification system (info/warn/error levels)
- Input prompts with vim.ui.input
- Terminal management (float/split modes)
- Wizard UI for project initialization

#### Telescope Extension
- `:Telescope haft dependencies` - Browse and add dependencies
- `:Telescope haft remove` - Browse and remove dependencies
- `:Telescope haft routes` - Browse API routes (jump to source)
- `:Telescope haft templates` - Browse templates (open/init)
- Configurable themes and layouts
- Fallback to native vim.ui.select

#### Lua API
- `require("haft")` - Main module with all public functions
- `require("haft.api")` - Direct API access
- `require("haft.config")` - Configuration management
- `require("haft.detection")` - Project detection utilities

### Planned
- User autocommand events (HaftProjectDetected, HaftGenerateComplete, etc.)

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
