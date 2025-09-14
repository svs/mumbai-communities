# Security

## Git Secrets Protection

This repository uses `git-secrets` to prevent accidental commits of sensitive information.

### What's Protected

- AWS access keys and secret keys
- Rails `SECRET_KEY_BASE` values
- API keys and tokens
- Private keys
- Database passwords
- Kamal secrets files

### Hooks Installed

- **Pre-commit**: Scans staged files for secrets before commit
- **Pre-push**: Scans repository before push to remote
- **Commit-msg**: Scans commit messages for secrets

### If Secrets Are Detected

If git-secrets blocks a commit or push:

1. **Review the flagged content** - ensure it's actually a secret
2. **Remove the secret** if it's real
3. **Add to `.gitallowed`** if it's a false positive
4. **Use environment variables** for real secrets instead

### Manual Scanning

Scan the entire repository:
```bash
git secrets --scan
```

Scan specific files:
```bash
git secrets --scan path/to/file
```

### Adding New Patterns

Add custom secret patterns:
```bash
git secrets --add 'your-pattern-here'
```

### Bypassing (Use Sparingly)

Only use `--no-verify` if you're absolutely sure:
```bash
git commit --no-verify -m "commit message"
```

## False Positives

If git-secrets flags legitimate code, add patterns to `.gitallowed`:

```bash
echo "your-false-positive-pattern" >> .gitallowed
```

## Rails Security Best Practices

- ✅ `config/master.key` is gitignored
- ✅ Using encrypted credentials (`config/credentials.yml.enc`)
- ✅ Environment variables for production secrets
- ✅ Parameter filtering for sensitive data
- ✅ No hardcoded passwords in source code