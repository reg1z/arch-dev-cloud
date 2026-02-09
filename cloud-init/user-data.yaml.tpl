#cloud-config

users:
  - name: ${username}
    groups: wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /usr/bin/zsh
    ssh_authorized_keys:
      - ${ssh_public_key}

write_files:
  - path: /home/${username}/.ssh/id_ed25519
    owner: ${username}:${username}
    permissions: "0600"
    content: |
      ${indent(6, ssh_private_key)}

  - path: /home/${username}/.ssh/config
    owner: ${username}:${username}
    permissions: "0644"
    content: |
      Host github.com
        IdentityFile ~/.ssh/id_ed25519
        IdentitiesOnly yes

%{ for key, value in api_keys ~}
  - path: /home/${username}/.config/environment.d/${key}.conf
    owner: ${username}:${username}
    permissions: "0600"
    content: |
      ${key}=${value}
%{ endfor ~}

runcmd:
  # Disk expansion
  - growpart /dev/vda 2 || true
  - btrfs filesystem resize max / || true

  # Git configuration
  - su - ${username} -c 'git config --global user.name "${git_user_name}"'
  - su - ${username} -c 'git config --global user.email "${git_user_email}"'
  - su - ${username} -c 'git config --global init.defaultBranch main'

  # ssh-agent auto-start in .zshrc
  - |
    cat >> /home/${username}/.zshrc << 'SSHAGENT'

    # Auto-start ssh-agent
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
    fi
    SSHAGENT
  - chown ${username}:${username} /home/${username}/.zshrc

  # Export API keys in .zshrc
%{ for key, value in api_keys ~}
  - echo 'export ${key}="${value}"' >> /home/${username}/.zshrc
%{ endfor ~}

  # Clone repositories
  - mkdir -p /home/${username}/repos
%{ for repo in repos_to_clone ~}
  - su - ${username} -c 'eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519 && ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null && git clone ${repo} ~/repos/$(basename ${repo} .git)'
%{ endfor ~}
  - chown -R ${username}:${username} /home/${username}/repos
