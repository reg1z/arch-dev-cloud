## Purpose

Defines what software and configuration is baked into the VM image during the Packer build.

## Requirements

### Requirement: Base system setup
The provisioning system SHALL include a script (`01-base.sh`) that performs a full system upgrade (`pacman -Syu`), installs base development tools (`base-devel`, `git`), creates a non-root build user, and installs `yay` from the AUR for AUR package access.

#### Scenario: System upgrade and yay installation
- **WHEN** `01-base.sh` runs on a fresh Arch cloud image
- **THEN** all system packages are upgraded, `base-devel` and `git` are installed, and `yay` is available for subsequent scripts to install AUR packages

### Requirement: Shell configuration
The provisioning system SHALL include a script (`02-shell.sh`) that installs `zsh` and `tmux`, installs oh-my-zsh, enables the built-in `vi-mode` plugin, and sets zsh as the default shell for the primary user (`arch`).

#### Scenario: zsh with oh-my-zsh and vi-mode
- **WHEN** `02-shell.sh` completes
- **THEN** zsh is installed, oh-my-zsh is installed, the `.zshrc` has `plugins=(vi-mode)` configured, and zsh is set as the default login shell

#### Scenario: tmux installed
- **WHEN** `02-shell.sh` completes
- **THEN** tmux is installed and available on the PATH

### Requirement: Editor configuration
The provisioning system SHALL include a script (`03-editor.sh`) that installs neovim and sets up the LazyVim starter configuration.

#### Scenario: Neovim with LazyVim
- **WHEN** `03-editor.sh` completes
- **THEN** neovim is installed, the LazyVim starter config is present in the appropriate config directory (`~/.config/nvim/`), and LazyVim plugin installation has been triggered

### Requirement: Language runtimes
The provisioning system SHALL include a script (`04-languages.sh`) that installs Python 3 with `venv` and `pip` support, installs nvm (node version manager), and uses nvm to install Node.js LTS version 24.

#### Scenario: Python 3 with venv
- **WHEN** `04-languages.sh` completes
- **THEN** `python3`, `python3 -m venv`, and `pip` are available

#### Scenario: Node.js via nvm
- **WHEN** `04-languages.sh` completes
- **THEN** nvm is installed, Node.js 24 LTS is installed as the default version, and `node` and `npm` are available

### Requirement: AI coding tools
The provisioning system SHALL include a script (`05-ai-tools.sh`) that installs Claude Code and OpenCode using their official install scripts.

#### Scenario: Claude Code installation
- **WHEN** `05-ai-tools.sh` completes
- **THEN** `claude` is available on the PATH

#### Scenario: OpenCode installation
- **WHEN** `05-ai-tools.sh` completes
- **THEN** `opencode` is available on the PATH

### Requirement: Ordered script execution
All provisioning scripts SHALL be executed by Packer as shell provisioners in numeric order (`01` through `05`). Each script SHALL be independently understandable and target a specific concern.

#### Scenario: Sequential execution
- **WHEN** Packer runs the provisioners
- **THEN** scripts execute in order: `01-base.sh`, `02-shell.sh`, `03-editor.sh`, `04-languages.sh`, `05-ai-tools.sh`

#### Scenario: Script failure halts build
- **WHEN** any provisioning script exits with a non-zero status
- **THEN** the Packer build fails and no image is produced
