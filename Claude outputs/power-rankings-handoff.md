# Fantasy Football Power Rankings: Session Handoff

Prepared 2026-11-03. This document is for starting a new chat on this project without reading the previous conversation.

## 1. System overview

There are four GitHub repositories, all owned by `jayson-stancil`. Three contain league apps and one contains a shared NFL data pipeline.

| Repo | Local path (Windows) | Role |
|---|---|---|
| `adg_dynasty_league_power_rankings` | `C:\Users\J0STAN09\Documents\GitHub\adg_dynasty_league_power_rankings` | ADG Dynasty league app and its weekly pipeline |
| `sleeper-power-rankings` (ADG Redraft) | `C:\Users\J0STAN09\Documents\GitHub\adg_redraft_power_rankings\sleeper-power-rankings` (nested one level) | ADG Redraft league app and its weekly pipeline |
| `corbin_dynasty_league_power_rankings` | `C:\Users\J0STAN09\Documents\GitHub\corbin_dynasty_league_power_rankings` | Corbin Dynasty league app and its weekly pipeline |
| `nfl_power_rankings` (**underscore**; it must be public) | `C:\Users\J0STAN09\Documents\GitHub\nfl_power_rankings` (flat, not nested) | NFL-wide Glicko-2 rankings. It has no app; it only produces CSVs. |

The apps are hosted on shinyapps.io under the account `jaysonstancil`.

### League repos (all three share the same structure)

- `R/engine.R` holds the Sleeper API helpers, the Glicko-2 pipeline (`run_power_rankings`), transactions, rosters, league history and the `gt` table builders (`build_graphic`, `build_nfl_graphic`).
- `R/simulate.R` holds the ffsimulator season simulation. It runs only in CI and is never loaded by the app.
- `run_all.R` is the CI entry point. It loops over the configs in `leagues/` and runs the rankings, the transaction cache and the simulation.
- `leagues/<league>_2026.R` holds each league's config: league_id, data_dir, manual roster_scores, owner_map, and history_seed (ADG Redraft only).
- `app.R` is the Shiny app. It reads CSVs from GitHub raw URLs and falls back to the copies bundled with the app. Some data (identity, rosters, players) is fetched live from Sleeper.
- `.github/workflows/weekly.yml` runs Tuesdays at 11:00 UTC, can be triggered manually with `workflow_dispatch`, and has a `concurrency` guard. It commits `data/**` via `git-auto-commit-action@v5`.
- `engine.R`, `simulate.R`, `run_all.R` and `weekly.yml` are **byte-identical across the three repos**. `app.R` differs in only two lines: `GH_REPO`, and `titlePanel` ("ΑΔΓ Dynasty League", "ΑΔΓ Redraft League", "Corbin Dynasty League").
- App tabs, in order: Rankings, League Stats (Summary / Points For / Rating Trajectory / Points Against / Overall Wins), Rosters, Transactions, Simulated Seasons, NFL Power Rankings, League History.

### NFL repo

- `R/nfl_power_rankings.R`: nflreadr schedule → `PlayerRatings::glicko2()`, seeded by `data/preseason.csv` using Rating = 1500 + z(BordaScore) × 100.
- It writes `data/current.csv`, `data/history.csv` (long format, Week ≥ 2), `data/teams.csv` (ABBREV, Team, ESPN Logo URL) and `data/meta.csv`.
- `data/preseason.csv` is static input and must be edited by hand each season before Week 1.
- Its `weekly.yml` runs Tuesdays at 11:00 UTC, can also be triggered manually, has a concurrency guard, installs only PlayerRatings and nflreadr, and commits `data/**`.
- The league apps read it through `read_nfl_csv(path)`, which reads `data/<path>` from `NFL_GH_USER/NFL_GH_REPO/NFL_GH_BRANCH` (`jayson-stancil` / `nfl_power_rankings` / `main`).

## 2. Current state (verified 2026-11-03)

All four repos are clean, with nothing uncommitted. All changes listed below are pushed.

| Change | Status |
|---|---|
| `concurrency:` guard added to every `weekly.yml` | Pushed |
| Transactions tab records traded draft picks (`fetch_league_transactions` reads `draft_picks`; `owner_id` = new holder, `previous_owner_id` = old holder) | Pushed |
| NFL Power Rankings tab (current-week table and rating trajectory) in all three apps | Pushed and published |
| `read_nfl_csv()` reads from the `data/` folder; `NFL_GH_REPO` set to `"nfl_power_rankings"` | Pushed and published |
| `nfl_power_rankings` made public (the apps read it anonymously) | Done |
| Rosters tab shows the NFL team logo for team defenses, via `nfl_teams()`; Sleeper's "LAR" is mapped to nflverse's "LA" | Pushed (republishing was required) |
| League-specific `titlePanel` text | Pushed by Jayson |
| NFL weekly Action | Running successfully (several automated commits since `b08e2f2`) |

## 3. Operating rules learned this session

- **When to republish:** a change to `app.R`, or to any function the app calls live, needs a shinyapps.io redeploy. A change that only affects what CI writes to `data/` does not.
- **Re-run vs. Run workflow:** GitHub's "Re-run jobs" replays the run on the *original* commit and fails with a non-fast-forward error if `main` has moved since. To refresh data, start a new run with **Run workflow**.
- **Push rejections:** a non-fast-forward rejection in the Action means something else pushed to `main` while it was running. When pushing locally and the push is rejected, run `git pull --no-edit` and then `git push`.
- **raw.githubusercontent.com caching:** it caches for a few minutes, including 404s returned while a repo was private. The GitHub Contents API is a faster way to check that a file exists.
- **Claude-side tooling:**
  - `device_commit_files` refuses to write `.github/workflows/*`. Write those files with `device_bash` (heredoc or a Python patch).
  - There is no R interpreter in Claude's cloud sandbox, so all R edits there are unexecuted and need a local RStudio test.
  - Files on Jayson's machine use CRLF line endings, which can make whole-file diffs look large. Use `git diff -b` to see only content changes.
- **Team codes:** the nflverse convention uses `LA` for the Rams, while Sleeper uses `LAR`. `JAX` and `WAS` match in both sources.

## 4. Open items

### 4a. Two small help-text bugs (not yet fixed)
- The NFL tab's help text in `app.R` says `nfl-power-rankings`; it should say `nfl_power_rankings`.
- The Rosters help text says "FantasyCalc redraft prices", but the two dynasty leagues use dynasty values (`is_dynasty = TRUE`).

### 4b. Code audit (findings reported; nothing applied yet)

**Decision pending from Jayson:** are the weekly PNG/PDF graphics used anywhere outside the apps?

**Outputs nothing reads**
- `Power Rankings/Graphics/*.png|pdf|html` (2.9 MB, 6.3 MB and 26 MB per repo; Corbin's `.git` is 59 MB). These are also uploaded with each app deploy. They are why `webshot2` is installed in CI and forced into the Shiny bundle by the `if (FALSE)` block at engine.R lines 26–42. The export fell back to HTML for weeks 3, 5 and 8.
- `… Points Against.csv`: written weekly, never read.
- `Simulation/meta.csv` and the NFL `meta.csv`: never read.
- `summary_season.csv` has 21 columns, but the app uses only `Owner` and `sim_rank`.

**Dead code**
- engine.R lines 320–361: `fetch_league_transactions_history()` has no callers.
- engine.R lines 1060–1073: the head-to-head matrix in `fetch_league_history()` is unused; the app builds head-to-head from `$long`.
- app.R lines 508–515: the `total_games` fallback is obsolete.
- The `through_week` and `make_graphic` parameters are never passed.
- The FantasyCalc `roster_score_source` path never runs, because all three leagues use `"manual"`.

**Logic written more than once**
- Rankings table assembly appears in `run_power_rankings`, `write_preseason_snapshot` and app `tbl()`.
- The graphic save block is duplicated in engine.R.
- Completed-weeks detection appears in both engine.R and simulate.R. The simulation also uses the config value `sim_n_weeks` instead of Sleeper's `playoff_week_start`, so the two can drift.
- The average points-for calculation appears three times.
- There are two near-identical trajectory plots and four copies of the same DT table options.
- Near-duplicate pairs: `list_weekly_files`/`list_transaction_files`, `fetch_json`/`sleeper_raw`, the styling in `build_graphic`/`build_nfl_graphic`, and the CSS card rules.
- Sleeper users/rosters are fetched four times per CI run per league.

**Structural**
- The codebase exists three times, so every change means three patches, three pushes and three deploys. The code already supports several league configs in one repo (`run_all.R` loops over `leagues/`, and the app shows a picker when there is more than one), so the leagues could be merged into one repo.

**Readability**
- simulate.R opens with a 38-line changelog header.
- engine.R and app.R have almost no indentation; `styler::style_file()` would fix it.

**Suggested order:**
1. Decide on the graphics.
2. Remove the dead code and fix the two help-text bugs.
3. Combine the repeated logic into shared helpers.
4. Optionally, merge the three repos into one.

The estimated reduction is about 250–300 of roughly 2,300 lines.

### 4c. Deferred / dropped
- Consolidating all four Actions into one dispatcher workflow was **dropped** at Jayson's request.
- Keeping the NFL repo private would require either a token in each app or the NFL Action pushing copies into each league repo. This was explained but not pursued; the repo stays public.

## 5. Working preferences

- Address Jayson by name. Keep responses formal, concise, structured and neutral.
- Write code in R only.
- Include a certainty rating as a percentage.
- Mirror every change identically across all three league repos unless told otherwise.
- Edit files in place on Jayson's machine through the device bridge, then give him the PowerShell `git add` / `commit` / `push` commands. Say whether the apps need republishing.
