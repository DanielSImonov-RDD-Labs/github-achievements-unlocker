# GitHub Achievements Unlocker

![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-automated-2088FF?logo=github-actions&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)
![Achievements](https://img.shields.io/badge/achievements-4_unlocked-gold)

One workflow. Four achievements. Fully automated.

---

## Achievements

| | Achievement | Trigger |
|---|---|---|
| 🔀 | **YOLO** | Merge a PR with no review |
| ⚡ | **Quickdraw** | Close a PR within 5 minutes |
| 🦈 | **Pull Shark** | Get multiple PRs merged |
| 👥 | **Pair Extraordinaire** | Co-author a merged commit |

---

## Setup

### 1. Enable Actions permissions

> **This step is required — the workflow will fail without it.**

Go to your repository:

**Settings → Actions → General → Workflow permissions**

- Select **"Read and write permissions"**
- Check **"Allow GitHub Actions to create and approve pull requests"**
- Click **Save**

### 2. Run the workflow

**Actions → Unlock GitHub Achievements → Run workflow**

The workflow opens and merges 10 pull requests automatically. Takes about 2 minutes.

---

## Requirements

- Public repository
- No branch protection rules on `main`
- Actions enabled (on by default)

No secrets or tokens needed — uses the built-in `GITHUB_TOKEN`.

---

## Notes

- Achievements appear on your profile within a few hours of the run completing
- Safe to run multiple times — branches are timestamped to avoid conflicts
- Replace `dummy@example.com` in the workflow with a real GitHub account email to reflect co-authorship on another profile

---

## License

MIT
