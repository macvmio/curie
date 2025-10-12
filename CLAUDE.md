# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Curie is a lightweight, open-source virtualization solution leveraging Apple's Virtualization.framework. It provides Docker-like container management for macOS VMs, allowing users to create, manage, and run isolated macOS instances.

## Common Commands

### Development Setup
```bash
# Install mise (required for development)
make setup

# Build the project in debug mode
make build
make sign

# Run locally
.build/debug/curie --help
```

### Testing and Quality
```bash
# Run all tests
make test

# Format source code (uses SwiftFormat)
make format

# Lint source code (uses SwiftLint)
make lint

# Autocorrect lint issues where possible
make autocorrect

# Run all CI checks locally (format, lint, build, sign, test)
make ready
```

### Running Tests
```bash
# Run all tests
xcrun swift test

# Run specific test target
xcrun swift test --filter CurieCoreTests

# Run specific test class
xcrun swift test --filter ImageCacheTests
```

### Building and Signing
```bash
# Clean build artifacts
make clean

# Build release version (builds, signs, notarizes, and staples)
make release

# Build in Xcode requires signing with entitlements
# See README section "Build and Run in Xcode" for configuration
```

## Architecture

### Module Structure

The project is organized into several Swift Package Manager modules:

- **Curie** - Entry point executable
- **CurieCommand** - Command-line interface layer using ArgumentParser
- **CurieCore** - Core business logic and VM management
- **CurieCommon** - Shared utilities and abstractions
- **CurieCoreMocks** / **CurieCommonMocks** - Test mocks

### Dependency Injection Pattern

The project uses **SCInject** (from SwiftCommons) for dependency injection:

- Each command has an associated `Assembly` class that registers dependencies
- `Command+Setup.swift` defines all subcommands and their assemblies
- Commands are split into:
  - **Static subcommands**: Built-in commands (build, run, images, etc.)
  - **Runtime subcommands**: Plugin-based commands (pull, push)
- The `Shared.resolver` singleton provides dependency resolution
- Assemblies are organized by layer: `commonAssemblies`, `commandAssemblies`, `coreAssemblies`

### Command → Interactor Pattern

Commands follow a consistent flow:
1. **Command** (CurieCommand layer) - Parses arguments using ArgumentParser
2. **Interactor** (CurieCore layer) - Executes business logic
3. Each command maps to a specific operation type in `Operation` enum
4. `DefaultInteractor` dispatches operations to specialized interactors (BuildInteractor, RunInteractor, etc.)
5. Async operations run through `RunLoop.run` for proper async handling

### Image and Container Management

- **ImageCache**: Central component managing images and containers
- **ImageReference**: Identifies images/containers with ID, descriptor, and type
- **ImageDescriptor**: Parsed reference format (repository:tag)
- **ImageID**: Unique 12-character hex identifier
- **VMBundle**: Directory structure containing VM files (.curie extension)
  - `machine-identifier.bin` - VM machine identifier
  - `hardware-model.bin` - Hardware model data
  - `auxilary-storage.bin` - Auxiliary storage
  - `disk.img` - Virtual disk image
  - `config.json` - VM configuration
  - `metadata.json` - Image metadata
  - `container.json` - Container-specific data
  - `machine-state.bin` - Machine state for pause/resume

Storage layout:
- Images: `~/.curie/.images/` (or `$CURIE_DATA_ROOT/.images/`)
- Containers: `~/.curie/.containers/` (or `$CURIE_DATA_ROOT/.containers/`)
- References follow: `repository/path:tag` → filesystem structure

### VM Configuration

VM behavior is controlled by `VMConfig` and `VMPartialConfig`:
- **CPUConfig**: Manual count, or min/max allowed
- **MemoryConfig**: Manual size (e.g., "8 GB"), or min/max allowed
- **DisplayConfig**: Width, height, pixelsPerInch
- **NetworkConfig**: NAT devices with MAC address modes (automatic, synthesized, manual)
- **SharedDirectoryConfig**: Directory sharing with automount support
- **ShutdownConfig**: Behavior on shutdown (stop or pause)

Config files are JSON-based and can be edited via `curie config <reference>`.

### Plugin System

Pull/push commands are implemented via executable plugins in `~/.curie/plugins/`:
- `pull` - Invoked as `pull --reference <reference>`
- `push` - Invoked as `push --reference <reference>`
- Plugins enable integration with OCI registries, S3, or custom storage backends
- Runtime subcommands are dynamically registered if plugins exist

### Virtualization Framework Integration

- Requires `com.apple.security.virtualization` entitlement
- VM launching handled by `ImageRunner` and `MacOSWindowAppLauncher`
- `VMConfigurator` translates VMConfig to VZVirtualMachineConfiguration
- `VirtualMachineDelegate` handles VM lifecycle events

## Important Implementation Details

### Entitlements Requirement
The binary must be signed with `Resources/curie.entitlements` containing `com.apple.security.virtualization` entitlement. Without this, VM operations fail.

### Reference Format
References follow Docker-like naming: `repository/path/to/image:tag`
- Container references are prefixed with `@<imageID>/`
- Images are identified by full reference or short 12-character ID

### Testing with Mocks
- Mock implementations exist for all external dependencies (FileSystem, Console, System, etc.)
- `InteractorsTestsEnvironment` provides test harness for interactors
- Tests verify behavior without actual VM operations

### Build System
- Uses `mise` task runner (wraps Swift Package Manager)
- All make commands delegate to `.mise/tasks/` scripts
- CI runs format, lint, build, sign, and test checks
- GitHub Actions workflows in `.github/workflows/`
