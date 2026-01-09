# onboarding checklist

environment setup for working with cracked dev containers.

## prerequisites

before starting, ensure you have:

- [ ] [docker](https://docs.docker.com/get-docker/) installed and running
- [ ] [gh cli](https://cli.github.com/) installed (`brew install gh` or see [installation docs](https://github.com/cli/cli#installation))
- [ ] [claude code](https://docs.anthropic.com/en/docs/claude-code) installed (`npm install -g @anthropic-ai/claude-code`)

verify installations:

```bash
docker --version
gh --version
claude --version
```

## github cli authentication

1. [ ] start the login flow:

   ```bash
   gh auth login
   ```

2. [ ] select your preferences when prompted:
   - **account**: GitHub.com (or your enterprise instance)
   - **protocol**: HTTPS (recommended) or SSH
   - **authentication**: Login with a web browser (easiest)

3. [ ] follow the browser prompts to complete OAuth

4. [ ] verify authentication:

   ```bash
   gh auth status
   ```

   expected output includes: `Logged in to github.com as <your-username>`

### alternative: token-based auth

if browser auth isn't available (e.g., headless environment):

```bash
# create a token at https://github.com/settings/tokens
# scopes needed: repo, read:org, workflow
echo "<your-token>" | gh auth login --with-token
```

or set the environment variable:

```bash
export GH_TOKEN="<your-token>"
```

## claude code authentication

1. [ ] start claude code:

   ```bash
   claude
   ```

2. [ ] follow the prompts to authenticate:
   - you'll be directed to sign in via browser
   - authorize the application when prompted

3. [ ] verify authentication by running a simple command:

   ```bash
   claude --version
   ```

   if authenticated, claude will run without auth prompts.

### alternative: api key auth

for environments without browser access:

```bash
export ANTHROPIC_API_KEY="<your-api-key>"
```

get your api key from [console.anthropic.com](https://console.anthropic.com/).

## verification

run these commands to confirm everything is set up:

```bash
# github
gh auth status

# docker
docker run hello-world

# claude (should not prompt for auth)
claude --version
```

## troubleshooting

### gh auth fails

- ensure you have network access to github.com
- try `gh auth logout` then `gh auth login` to reset
- check firewall/proxy settings if behind corporate network

### claude auth issues

- clear cached credentials: `claude logout` (if available)
- verify api key is valid at console.anthropic.com
- check that `ANTHROPIC_API_KEY` is exported in your shell

### docker issues

- ensure docker daemon is running: `docker info`
- on linux, you may need to add your user to the docker group:
  ```bash
  sudo usermod -aG docker $USER
  # then log out and back in
  ```

## next steps

once authenticated:

1. pull or build the base image (see [base-image spec](specs/base-image.md))
2. run a container with your preferred child image (see [child-images spec](specs/child-images.md))
3. start developing
