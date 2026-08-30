# =============================================================================
# League config: ADG Dynasty League, 2026-2027 season
# Returns a config list consumed by run_all.R and app.R.
# To add another league, copy this file and edit the values.
# =============================================================================

list(
    league_id    = "1326804444129558528",
    league_tag   = "ADG Dynasty",
    season_label = "2026-2027",
    data_dir     = "data/adg_dynasty",

    # Preseason/roster strength scoring, used for (a) Glicko-2 initial ratings
    # and (b) the ROST SCORE column in League Stats > Summary.
    #   "fantasycalc" - computed live each run: sums FantasyCalc player values
    #                   (see is_dynasty/ppr below) per Sleeper roster, then
    #                   ranks teams 1-8 (1 = strongest roster).
    #   "manual"      - uses the roster_scores vector below instead.
    #   NULL          - disabled; all teams start at 1500, ROST SCORE hidden.
    roster_score_source = "manual",
    is_dynasty = TRUE,   # dynasty rosters carry over; FALSE = redraft values
    ppr        = 1,      # matches this league's full-PPR scoring

    # Season simulation (ffsimulator), feeds the "Simulated Seasons" tab.
    # Runs only in the weekly GitHub Action (heavy deps, not in the Shiny
    # app); set FALSE to skip it entirely for this league.
    enable_simulation = TRUE,
    sim_n_seasons = 250,  # more = smoother odds, slower CI run
    sim_n_weeks   = 14,   # matches this league's regular-season length (playoffs start week 15)

    # Manual preseason roster power ranking, only used because
    # roster_score_source == "manual" above. Owner supplied a 1-8 ranking
    # (1 = best); converted here to a "higher = stronger" score (9 - rank)
    # and ordered by roster_id 1-8 (PlayerRatings::glicko2 z-scores this
    # vector to seed initial ratings at mean 1500 / SD 100):
    #   roster_id 1  jstancil      (rank 2) -> 7
    #   roster_id 2  ethimme       (rank 1) -> 8
    #   roster_id 3  Lacy15        (rank 7) -> 2
    #   roster_id 4  ColKelly      (rank 5) -> 4
    #   roster_id 5  tommypack     (rank 6) -> 3
    #   roster_id 6  Ethanpurdy10  (rank 8) -> 1
    #   roster_id 7  Kellen1923    (rank 3) -> 6
    #   roster_id 8  elijahsartin  (rank 4) -> 5
    # Re-derive this vector each preseason before Week 1 of a new season.
    roster_scores = c(7, 8, 2, 4, 3, 1, 6, 5),

    # Canonical owner names keyed by Sleeper user_id (stable across seasons).
    # Set to NULL to use Sleeper display names.
    owner_map = data.frame(
      user_id = c("940759302413967360", "940763315846889472",
                  "940776278410629120", "940792224906813440",
                  "940794771403046912", "940811524497707008",
                  "940813195177062400", "941159594544443392"),
      owner   = c("KING COMMISH", "Ethan Thimme", "Jordan Lacy", "Colin Kelly",
                  "Tommy Pack", "Ethan Purdy", "Kellen McHugh", "Elijah Sartin"),
      stringsAsFactors = FALSE
    )

    # No history_seed needed: this league's Sleeper chain (2026 -> 2025 ->
    # 2024 -> 2023, previous_league_id NULL) is entirely API-native, so
    # fetch_league_history() reconstructs champions/all-time records/H2H
    # for every season live with no manual seed data required.
)
