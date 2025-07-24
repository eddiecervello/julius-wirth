# GitHub Actions Secrets Setup

This document explains how to set up the required secrets for the CI/CD pipeline.

## Required Secrets

### 1. SSH_PRIVATE_KEY
This is the SSH private key used to access your production server.

**How to set up:**
1. Use your existing SSH key (`julius-wirth-access-key.pem`)
2. Go to GitHub repository → Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `SSH_PRIVATE_KEY`
5. Value: Paste the entire contents of your SSH private key file
6. Click "Add secret"

**To get the key contents:**
```bash
cat ~/.ssh/julius-wirth-access-key.pem
```

## Optional Secrets (for notifications)

### SLACK_WEBHOOK (optional)
If you want Slack notifications:
1. Create a Slack webhook URL
2. Add as secret: `SLACK_WEBHOOK`

### DISCORD_WEBHOOK (optional)
If you want Discord notifications:
1. Create a Discord webhook URL
2. Add as secret: `DISCORD_WEBHOOK`

## Verification

After setting up the secrets:
1. Go to Actions tab in GitHub
2. Run the "Deploy to Production" workflow manually
3. Check the logs to ensure deployment succeeds

## Security Notes

- Never commit SSH keys to the repository
- Rotate SSH keys periodically
- Use deployment keys with limited permissions when possible
- Review GitHub Actions logs to ensure secrets aren't exposed