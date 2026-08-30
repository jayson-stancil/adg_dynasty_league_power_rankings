# ADG Dynasty League — Power Rankings

Automated fantasy football power rankings: a scheduled GitHub Action pulls
matchups from the Sleeper API every Tuesday, runs a Glicko-2 rating pipeline,
and commits the results to `data/`. A Shiny app (`app.R`) presents the
rankings with Sleeper team names and avatars, week-over-week movement, and
rating trajectories.

This repo mirrors the structure of `sleeper-power-rankings` (ADG Redraft),
scoped to a single league.

## Structure

| Path | Role |
|---|---|
| `R/engine.R` | League-agnostic pipeline (`run_power_rankings()`) |
| `leagues/adg_dynasty_2026.R` | League config (ID, owner map, preseason scores) |
| `run_all.R` | Runs the pipeline for the league config |
| `data/` | Weekly outputs, committed by the Action |
| `app.R` | Shiny app |
| `.github/workflows/weekly.yml` | Tuesday 6 AM ET schedule + manual trigger |

## League

- Sleeper league ID: `1326804444129558528`
- Format: Dynasty, 8 teams, full PPR
- Ratings are season-contained (Glicko-2 does not carry over between
  seasons); the preseason ranking below reseeds initial ratings each year
- Full league history is Sleeper-native back to 2023 (2023 -> 2024 -> 2025 ->
  2026, `previous_league_id` chain terminates at 2023) — no manual history
  seed is needed; the League History tab reconstructs champions, all-time
  records, and head-to-head live from the API, and `update_transactions_cache()`
  in `run_all.R` caches every season's transactions the same way

## Updating the preseason ranking each season

`leagues/adg_dynasty_2026.R` uses `roster_score_source = "manual"` with a
`roster_scores` vector derived from a 1-8 preseason power ranking (1 = best).
Before Week 1 of a new season:

1. Get the new 1-8 ranking by team
2. Convert each rank to a "higher = stronger" score (`9 - rank`)
3. Reorder that score by ascending `roster_id` (check current roster IDs via
   the Sleeper API, since they can differ from the previous season if anyone
   leaves the league) and replace `roster_scores`
4. Copy the file to e.g. `leagues/adg_dynasty_2027.R`, update `league_id` if
   Sleeper issues a new one for the new season, and update `season_label`

## Deployment

The app deploys from this repo (Posit Connect Cloud or shinyapps.io).
`GH_USER`/`GH_REPO` in `app.R` point at this repo so the app reads fresh data
from raw.githubusercontent.com; it falls back to the bundled `data/` copy if
offline.

## Method

Glicko-2 (PlayerRatings), recomputed each week over all completed games.
Initial-status volatility is set by latest-week performance (top scorer 0.08;
above-median winner 0.06; below-median winner 0.05; above-median loser 0.04;
else 0.03). Preseason ratings are a Gaussian transform of the manual roster
scores above (mean 1500, SD 100), deviation 200.
