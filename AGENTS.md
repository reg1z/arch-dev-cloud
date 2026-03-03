# AGENTS.md

Guidance for AI agents working in this repository.

## What this project is

A pipeline that produces a reproducible Arch Linux development VM image and deploys it to cloud providers. The primary artifact is a QCOW2 file built inside a Docker container using QEMU + Packer, then uploaded and deployed via Terraform.

## Architecture

```
make build
  └── Docker (build/) runs Packer
        ├── file provisioner: uploads dots/ → /tmp/dots/ on VM
        └── shell provisioners (in order):
              01-base.sh       → pacman upgrade, base-devel, yay
              02-shell.sh      → zsh, oh-my-zsh, tmux
              03-editor.sh     → neovim, LazyVim starter
              04-languages.sh  → Python, nvm/Node.js, Rust, rtk
              05-ai-tools.sh   → Claude Code, OpenCode
              06-dotfiles.sh   → installs dots/ into the image
              99-cleanup.sh    → strip caches

make upload-{gcp,aws,az}  → host-side scripts, convert + push image
make deploy-{gcp,aws,az}  → terraform apply in terraform/{gcp,aws,azure}/
```

## Key constraints

- **Script order matters.** `06-dotfiles.sh` must run after `03-editor.sh` (LazyVim is cloned there) because it overwrites the LazyVim config stubs. Scripts use `set -euo pipefail`; any failure aborts the build.
- **Dots are uploaded first.** The Packer `file` provisioner runs before all shell scripts, placing `dots/` at `/tmp/dots/` on the VM. The Docker `make build` target mounts `dots/` into the build container at `/packer/dots/`.
- **Secrets are never baked in.** The image has no user-specific data. SSH keys, API keys, git config, and repos are injected at boot via cloud-init from `secrets.tfvars`.
- **The VM user is `arch`.** All provisioning scripts operate on `/home/arch`. Cloud-init at deploy time configures the same user.

## Where things live

| Concern | Location |
|---|---|
| Shell dotfiles (.zshrc, .bashrc, aliases, tmux_fns) | `dots/shell/` |
| Neovim lua config overrides | `dots/nvim/lua/config/` |
| Tmux config | `dots/tmux/tmux.conf` |
| Dotfile install logic | `packer/scripts/06-dotfiles.sh` |
| Language/tool installs | `packer/scripts/04-languages.sh`, `05-ai-tools.sh` |
| Cloud-init user-data template | `cloud-init/user-data.yaml.tpl` |
| Terraform per provider | `terraform/{gcp,aws,azure}/` |
| Living specs | `openspec/specs/{image-build,provisioning,image-upload,vm-deploy}/spec.md` |

## Making changes

**Add a new CLI tool baked into the image:** install it in the appropriate `packer/scripts/` file (`04-languages.sh` for language runtimes, `05-ai-tools.sh` for AI tools). If it needs PATH setup, add it to `dots/shell/.zshrc` and `dots/shell/.bashrc`.

**Change shell environment (aliases, functions, env vars):** edit files in `dots/shell/`. `06-dotfiles.sh` copies them to `~/.config/shell/` and replaces `~/.zshrc` and `~/.bashrc`.

**Change neovim config:** edit `dots/nvim/lua/config/options.lua` or `keymaps.lua`. `06-dotfiles.sh` copies `dots/nvim/lua/` over the LazyVim starter stubs at `~/.config/nvim/lua/`.

**Change what runs at VM deploy time (not build time):** edit `cloud-init/user-data.yaml.tpl` and the relevant Terraform `variables.tf`.

**Add a new cloud provider:** add upload and Terraform configs following the pattern of the existing providers; add `upload-<provider>` and `deploy-<provider>` targets to the Makefile.

## Specs

Formal requirements live in `openspec/specs/`. Each subsystem has a `spec.md` with requirements and BDD-style scenarios. Consult these before changing behavior that spans multiple files. Archived change proposals are in `openspec/changes/archive/`.
