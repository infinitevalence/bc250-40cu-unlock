# AGENTS.md — Operating procedures for coding agents

## Git push to GitHub

### SSH (preferred)

```sh
# Use the system openssh agent socket, load the key, then push
SSH_AUTH_SOCK=/run/user/1000/openssh_agent ssh-add ~/.ssh/id_rsa

cd /home/infinitevalence/bc250-40cu-unlock
SSH_AUTH_SOCK=/run/user/1000/openssh_agent git push origin ALPINE
```

- **Branch:** `ALPINE`
- **Key:** `~/.ssh/id_rsa` (configured in `~/.ssh/config`)

> The passphrase is provided via SSH_ASKPASS when prompted. The system
> openssh-agent at `/run/user/1000/openssh_agent` must be used — a fresh
> `eval $(ssh-agent -s)` will create an orphaned agent whose socket the
> system won't resolve.
