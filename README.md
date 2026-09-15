## Platform Lifecycle & Management

The platform lifecycle is managed via three primary scripts located in `infrastructure/bootstrap/`. These scripts provide deterministic environment setup, rapid local development loops, and complete state resets.

| Script         | Execution Time | Purpose & Workflow                                                                                                                                                        |
| :------------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `bootstrap.sh` | ~1–2 min       | **Initial Setup:** Verifies tools, creates `RcsApi`, configures host Nginx, and launches Docker containers (`DefectDojo` & `rcs-api`).                                    |
| `rerun.sh`     | ~10–15 sec     | **Fast Iteration:** Rebuilds the target API container, executes the security scanning pipeline, and pushes findings to DefectDojo without restarting persistent services. |
| `reset.sh`     | ~1–2 min       | **Clean State Reset:** Wipes container volumes, purges `./reports/raw` and `./evidence` archives, prunes Docker cache, and re-bootstraps from scratch.                    |

---

### Usage Commands

#### 1. Initial Setup (Post-SSH)

Run immediately after accessing a newly created Droplet:

```bash
chmod +x infrastructure/bootstrap/*.sh pipelines/*.sh
./infrastructure/bootstrap/bootstrap.sh
```

#### 2. Fast Iteration Loop

Use while modifying application code, tweaking scan rules in policies/security-policy.yaml, or testing scanner behavior:

```bash
./infrastructure/bootstrap/rerun.sh
```

#### 3. Full Platform Reset

Use before live demonstrations or when resetting DefectDojo findings back to baseline:

```bash
./infrastructure/bootstrap/reset.sh
```

---

### Summary PDF Document Features

The generated PDF document (`README_Lifecycle_Documentation.pdf`) includes:

- **Dark-mode Technical Layout:** Designed with a slate theme (`#0f172a`) styled for cloud & DevSecOps platforms.
- **Execution & Timing Breakdown:** Structured table with script scopes, execution times, and target environments.
- **Command Reference Blocks:** Syntax-highlighted code blocks for initial execution, fast iteration, and clean reset sequences.
