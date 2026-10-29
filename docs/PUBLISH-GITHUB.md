# Publish to NEW GitHub repository

This repository was **not** automatically published. The connected GitHub API capability in this conversation can write to existing GitHub repositories but does not provide a new-repository creation action. No existing repository should be overwritten to approximate a new repo.

1. On GitHub, create a **new empty repository** `m365-cloud-tenant-migration` under your account. Choose public only after verifying ALL included files are sanitized; private is recommended for actual customer migrations. Do not initialize README to avoid a conflicting root commit.
2. In terminal with Git and GitHub CLI authenticated (`gh auth login`) from extracted project folder:

```bash
git init -b main
git add .
git commit -m 'Initial safe cloud-only M365 migration toolkit'
gh repo create m365-cloud-tenant-migration --private --source=. --remote=origin --push
```

Or create on GitHub web first and then run `git remote add origin <URL> && git push -u origin main`. Do **not** publish real tenant inventories, licenses/identity maps containing employee data or secrets (`output/` and `config/local.json` are ignored). If using a company organization, confirm repository owner and access policies with IT/security.

The commands are guidance and were **not executed against the user's GitHub account** by this project.
