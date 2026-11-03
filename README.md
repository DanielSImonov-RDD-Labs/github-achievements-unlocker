# GitHub Achievements Unlocker

![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-automated-2088FF?logo=github-actions&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

Earns every GitHub achievement that can be automated, credited to your own account, and shows what is left.

---

## Achievements

### Automated

| | Achievement | Tiers | Trigger |
|---|---|---|---|
| 🔀 | **YOLO** | 1 | Merge a PR with no review |
| ⚡ | **Quickdraw** | 1 | Close an issue within 5 minutes |
| 🦈 | **Pull Shark** | 2 / 16 / 128 / 1024 | Get PRs merged |
| 👥 | **Pair Extraordinaire** | 1 / 10 / 24 / 48 | Merge PRs with a real co-author (`--coauthor`) |

### Needs real people

These are not automated, because faking them means fake accounts or paid stars.

| | Achievement | Tiers | How to earn it |
|---|---|---|---|
| 🧠 | **Galaxy Brain** | 2 / 8 / 16 / 32 | Have answers accepted in [Discussions](https://github.com/orgs/community/discussions?discussions_q=is%3Aunanswered) |
| ⭐ | **Starstruck** | 16 / 128 / 512 / 4096 | Get real stars on one of your repositories |
| 💖 | **Public Sponsor** | 1 | Sponsor someone on [GitHub Sponsors](https://github.com/sponsors/explore) (paid) |

### Cannot be earned right now

- **Heart On Your Sleeve**, **Open Sourcerer**: [disabled by GitHub](https://github.com/orgs/community/discussions/191031)
- **Arctic Code Vault Contributor**, **Mars 2020 Contributor**: retired

---

## Setup

Needs the [GitHub CLI](https://cli.github.com) and a public repository with no branch protection on the default branch.

```bash
gh auth login
git clone https://github.com/DanielSImonov-RDD-Labs/github-achievements-unlocker.git
cd github-achievements-unlocker
```

## Usage

```bash
./unlock.sh status            # what you have and what is next
./unlock.sh run --dry-run     # print the plan, change nothing
./unlock.sh run               # reach 16 public merged PRs
```

| Option | Default | Meaning |
|---|---|---|
| `--repo OWNER/NAME` | this clone | Public repository to open PRs in |
| `--pr-target N` | `16` | Total public merged PRs to reach. PRs you already have count, so a stopped run can simply be repeated |
| `--coauthor LOGIN` | none | Account that agreed to co-author every PR of this run |
| `--delay SECONDS` | `40` | Pause between PRs, to stay under GitHub's limit of 500 writes per hour |

Timing at the default delay: 16 PRs take about 15 minutes, 128 about 2 hours, 1024 about 14 hours.

### Co-authors

`--coauthor` shows the commits on that person's profile too, so only use an account that agreed to it. Made-up emails such as `dummy@example.com` earn nothing.

### From GitHub Actions

The built-in `GITHUB_TOKEN` acts as `github-actions[bot]`, so everything it does is credited to the bot and not to you. To run from Actions:

1. Create a [fine-grained token](https://github.com/settings/personal-access-tokens/new) for this repository with read and write access to **Contents**, **Pull requests** and **Issues**.
2. Save it as a repository secret named `ACHIEVEMENTS_TOKEN`.
3. Open **Actions → Unlock GitHub Achievements → Run workflow**.

A single job stops after 6 hours. Run it again to continue.

---

## What is not confirmed

GitHub does not document the achievement rules. The tiers above come from community lists.

- **Self-merged PRs and Pull Shark tiers:** YOLO and Pair Extraordinaire have been seen unlocking within seconds of a self-merged public PR. Pull Shark has not been seen reacting that directly, so go one tier at a time: run to the next tier, wait 48 hours, check `./unlock.sh status`, and only then continue.
- **Private PRs:** an account with hundreds of merged private PRs was still shown at tier 1, so this tool only counts public ones.

## Terms of use

GitHub's [Acceptable Use Policies](https://docs.github.com/en/site-policy/acceptable-use-policies/github-acceptable-use-policies) prohibit excessive automated bulk activity and automated inauthentic activity, and can lead to account suspension. Higher tiers mean more of exactly that, so the risk grows with `--pr-target`. The account is yours and so is that decision.

This tool does not automate stars, followers or fake accounts.

---

## License

MIT
