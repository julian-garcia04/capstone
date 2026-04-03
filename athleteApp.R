# ============================================================
#  Athlete Recruitment Profile App
#  install.packages(c("shiny","jsonlite","plotly","dplyr","tidyr"))
#
#  DATA PATHS — update these two lines for your environment:
#    BENCHMARK_PATH : Django fixture JSON (initial_benchmarks.json)
#    ATHLETE_PATH   : Athlete JSON exported from your Django API/fixture
#                     Leave as NULL to use the built-in seed data.
# ============================================================

library(shiny)
library(jsonlite)
library(plotly)
library(dplyr)
library(tidyr)

# ── PATH CONFIGURATION ────────────────────────────────────────────────────────
BENCHMARK_PATH <- "C:/capstone/core/fixtures/initial_benchmarks.json"
ATHLETE_PATH   <- NULL   # set to a file path when you have real athlete JSON

# ── 1. Load & parse benchmarks from JSON ─────────────────────────────────────
# Handles: null threshold_min / threshold_max, any extra fields, any order
load_benchmarks <- function(path) {
  raw <- fromJSON(path, simplifyDataFrame = FALSE)
  rows <- lapply(raw, function(x) {
    f <- x$fields
    data.frame(
      division      = as.character(f$division),
      test_name     = as.character(f$test_name),
      category      = as.character(f$category %||% ""),
      threshold_min = if (is.null(f$threshold_min) || length(f$threshold_min) == 0)
        NA_real_ else as.numeric(f$threshold_min),
      threshold_max = if (is.null(f$threshold_max) || length(f$threshold_max) == 0)
        NA_real_ else as.numeric(f$threshold_max),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

# Null-coalescing helper (used above)
`%||%` <- function(a, b) if (!is.null(a)) a else b

benchmarks <- load_benchmarks(BENCHMARK_PATH)

# ── 2. Test metadata — maps JSON test_name → athlete field names ──────────────
# These test_name values must exactly match what is in your benchmark JSON.
# The field_name values must exactly match the column names in your athlete data.
test_map <- data.frame(
  test_name    = c("40-Yard Dash",
                   "Vertical Jump",
                   "T-Test",
                   "Yo-Yo Intermittent Recovery Test (Beep Test)"),
  field_name   = c("sprint_40yd",
                   "vertical_jump",
                   "agility_t",
                   "beep_level"),
  label        = c("40-Yard Dash (sec)",
                   "Vertical Jump (in)",
                   "T-Test Agility (sec)",
                   "Beep Test (level)"),
  short_label  = c("40-Yd Dash", "Vertical Jump", "T-Test", "Beep Test"),
  lower_better = c(TRUE, FALSE, TRUE, FALSE),
  unit         = c("sec", "in", "sec", "level"),
  stringsAsFactors = FALSE
)

# Build the benchmark cutoff table.
# For time-based tests (lower_better): cutoff = threshold_max (the upper limit to beat)
# For score-based tests (!lower_better): cutoff = threshold_min (the floor to reach)
bm <- benchmarks %>%
  filter(test_name %in% test_map$test_name) %>%
  left_join(test_map, by = "test_name") %>%
  mutate(cutoff = ifelse(lower_better, threshold_max, threshold_min)) %>%
  select(division, field_name, label, short_label, lower_better, cutoff, unit)

# Verify we have D1/D2/D3 rows for each mapped test — warn if anything is missing
expected_rows <- length(test_map$field_name) * 3
if (nrow(bm) < expected_rows) {
  missing <- setdiff(
    paste0(rep(c("Division 1","Division 2","Division 3"), each = nrow(test_map)),
           " | ", rep(test_map$test_name, 3)),
    paste0(bm$division, " | ", bm$test_name %||% bm$label)
  )
  warning("Some benchmark rows are missing from the JSON. Check test_name spelling.\n",
          "Expected ", expected_rows, " rows, got ", nrow(bm))
}

get_cutoff <- function(bm_df, fld, div) {
  val <- bm_df %>% filter(field_name == fld, division == div) %>% pull(cutoff)
  if (length(val) == 0) return(NA_real_) else val[1]
}

# ── 3. Load athlete data ───────────────────────────────────────────────────────
# When ATHLETE_PATH is set, athletes and their test history are parsed from that
# JSON.  The expected format is a Django fixture for your Athlete / AthleteTest
# models (same structure as initial_benchmarks.json but for core.athlete and
# core.athletetest).
#
# Expected athlete JSON structure:
# [
#   { "model": "core.athlete",
#     "pk": 1,
#     "fields": { "user": 1, "grad_year": 2025, "height_in": 74, "weight_lb": 195 }
#   },
#   { "model": "auth.user",
#     "pk": 1,
#     "fields": { "username": "john_doe" }
#   },
#   { "model": "core.athletetest",
#     "pk": 1,
#     "fields": {
#       "athlete": 1,
#       "test_date": "2025-01-01",
#       "sprint_40yd": 4.50,
#       "vertical_jump": 34.0,
#       "agility_t": 8.5,
#       "beep_level": 21.0
#     }
#   }
# ]
#
# If ATHLETE_PATH is NULL the seed data from seed_athletes.py is used instead.

load_athletes <- function(path) {
  raw   <- fromJSON(path, simplifyDataFrame = FALSE)
  users <- Filter(function(x) x$model == "auth.user",       raw)
  aths  <- Filter(function(x) x$model == "core.athlete",    raw)
  tests <- Filter(function(x) x$model == "core.athletetest", raw)
  
  # Build user lookup: pk -> username
  user_map <- setNames(
    sapply(users, function(u) u$fields$username),
    sapply(users, function(u) as.character(u$pk))
  )
  
  # Build athletes data frame
  ath_rows <- lapply(aths, function(a) {
    user_pk <- as.character(a$fields$user)
    uname   <- user_map[user_pk] %||% paste0("athlete_", a$pk)
    data.frame(
      username     = uname,
      display_name = gsub("_", " ", tools::toTitleCase(uname)),
      grad_year    = a$fields$grad_year    %||% NA_integer_,
      height_in    = a$fields$height_in    %||% NA_real_,
      weight_lb    = a$fields$weight_lb    %||% NA_real_,
      athlete_pk   = a$pk,
      stringsAsFactors = FALSE
    )
  })
  athletes_df <- do.call(rbind, ath_rows)
  
  # Add latest test scores directly onto the athlete row
  # (uses most recent test_date per athlete)
  for (fld in test_map$field_name) athletes_df[[fld]] <- NA_real_
  
  test_rows <- lapply(tests, function(t) {
    ath_pk <- as.character(t$fields$athlete)
    row <- data.frame(athlete_pk = as.integer(ath_pk),
                      test_date  = as.Date(t$fields$test_date %||% "1970-01-01"),
                      stringsAsFactors = FALSE)
    for (fld in test_map$field_name)
      row[[fld]] <- if (!is.null(t$fields[[fld]])) as.numeric(t$fields[[fld]]) else NA_real_
    row
  })
  hist_df <- do.call(rbind, test_rows)
  
  # Latest scores per athlete
  latest <- hist_df %>%
    group_by(athlete_pk) %>%
    filter(test_date == max(test_date)) %>%
    slice(1) %>%
    ungroup()
  
  for (fld in test_map$field_name) {
    match_idx <- match(athletes_df$athlete_pk, latest$athlete_pk)
    athletes_df[[fld]] <- latest[[fld]][match_idx]
  }
  
  # History for progress chart (all sessions, not just latest)
  hist_df$username <- user_map[
    as.character(athletes_df$athlete_pk[match(hist_df$athlete_pk, athletes_df$athlete_pk)])
  ]
  
  list(athletes = athletes_df, history = hist_df)
}

# ── Seed data (mirrors seed_athletes.py exactly — all 14 athletes) ───────────
seed_athletes <- data.frame(
  username = c(
    "d1_player", "d2_player", "d3_player", "hybrid_player",
    "pct_60_player", "pct_80_player", "pct_90_player",
    "null_all", "null_partial", "zero_scores",
    "speed_only", "power_only", "almost_d1", "overachiever"
  ),
  display_name = c(
    "D1 Player", "D2 Player", "D3 Player", "Hybrid Player",
    "60% Player", "80% Player", "90% Player",
    "No Scores", "Partial Scores", "Zero Scores",
    "Speed Only", "Power Only", "Almost D1", "Overachiever"
  ),
  grad_year = c(
    2025, 2026, 2026, 2027,
    2027, 2026, 2025,
    2028, 2027, 2027,
    2026, 2025, 2025, 2025
  ),
  height_in = c(
    74, 71, 69, 73,
    68, 70, 72,
    71, 73, 69,
    70, 76, 73, 75
  ),
  weight_lb = c(
    195, 175, 160, 185,
    155, 168, 180,
    170, 178, 162,
    158, 215, 188, 192
  ),
  sprint_40yd = c(
    4.50, 4.75, 5.00, 4.55,    # originals
    8.33, 6.25, 5.56,           # 60/80/90%
    NA,   4.90, 4.80,           # null/partial/zero
    4.40, 6.10, 5.10, 4.20     # variety
  ),
  vertical_jump = c(
    34.0, 29.0, 24.0, 25.0,
    10.8, 14.4, 16.2,
    NA,   NA,   0,
    12.0, 38.0, 17.5, 40.0
  ),
  agility_t = c(
    8.5,  9.2,  10.0,  8.7,
    15.0, 11.25, 10.0,
    NA,   9.5,   9.8,
    11.5, 11.0, 9.15, 7.8
  ),
  beep_level = c(
    21.0, 18.0, 15.0, 16.0,
    7.8,  10.4, 11.7,
    NA,   NA,   0,
    8.0,  9.0,  12.5, 25.0
  ),
  athlete_pk = 1:14,
  stringsAsFactors = FALSE
)

# History: only the original 4 have multi-session history.
# All other athletes default to a single session on 2025-01-01.
seed_history <- rbind(
  # Original 4 — 3 sessions each
  data.frame(
    username      = rep(c("d1_player","d2_player","d3_player","hybrid_player"), each = 3),
    athlete_pk    = rep(1:4, each = 3),
    test_date     = rep(as.Date(c("2024-06-01","2024-09-01","2025-01-01")), times = 4),
    sprint_40yd   = c(4.65,4.55,4.50, 4.90,4.80,4.75, 5.20,5.10,5.00, 4.70,4.60,4.55),
    vertical_jump = c(31,  32,  34,   26,  28,  29,   21,  23,  24,   22,  24,  25),
    agility_t     = c(8.9, 8.7, 8.5,  9.5, 9.3, 9.2, 10.5,10.2,10.0,  9.0, 8.8, 8.7),
    beep_level    = c(19,  20,  21,   16,  17,  18,   13,  14,  15,   14,  15,  16),
    stringsAsFactors = FALSE
  ),
  # Remaining 10 — single session
  data.frame(
    username = c(
      "pct_60_player","pct_80_player","pct_90_player",
      "null_all","null_partial","zero_scores",
      "speed_only","power_only","almost_d1","overachiever"
    ),
    athlete_pk    = 5:14,
    test_date     = rep(as.Date("2025-01-01"), 10),
    sprint_40yd   = c(8.33, 6.25, 5.56, NA,   4.90, 4.80, 4.40, 6.10, 5.10, 4.20),
    vertical_jump = c(10.8, 14.4, 16.2, NA,   NA,   0,    12.0, 38.0, 17.5, 40.0),
    agility_t     = c(15.0, 11.25,10.0, NA,   9.5,  9.8,  11.5, 11.0, 9.15, 7.8),
    beep_level    = c(7.8,  10.4, 11.7, NA,   NA,   0,    8.0,  9.0,  12.5, 25.0),
    stringsAsFactors = FALSE
  )
)

if (!is.null(ATHLETE_PATH) && file.exists(ATHLETE_PATH)) {
  loaded   <- load_athletes(ATHLETE_PATH)
  athletes <- loaded$athletes
  history  <- loaded$history
} else {
  athletes <- seed_athletes
  history  <- seed_history
}

# ── 4. Schools ────────────────────────────────────────────────────────────────
schools <- data.frame(
  school   = c("State University","City College","Tech Institute",
               "Riverside U","Lakewood College","Northern State"),
  division = c("Division 1","Division 1","Division 2",
               "Division 2","Division 3","Division 3"),
  stringsAsFactors = FALSE
)

div_choices <- c(
  "Division I  (highest level)"  = "Division 1",
  "Division II (mid level)"      = "Division 2",
  "Division III (entry level)"   = "Division 3"
)

metric_choices <- setNames(test_map$field_name, test_map$label)

# ── 5. Helpers ────────────────────────────────────────────────────────────────
meets_benchmark <- function(score, cutoff, lower_better) {
  if (is.na(cutoff) || is.na(score)) return(NA)
  if (lower_better) score <= cutoff else score >= cutoff
}

pct_of_benchmark <- function(score, cutoff, lower_better) {
  # Only bail on truly missing data — a score of 0 is valid and should display
  if (is.na(cutoff) || is.na(score)) return(NA_real_)
  # For lower-is-better (time tests): avoid division by zero if score is 0
  if (lower_better && score == 0) return(NA_real_)
  if (lower_better) round((cutoff / score) * 100, 1)
  else              round((score  / cutoff) * 100, 1)
}

# Safe score fetch — NULL/missing returns NA, but 0 is kept as 0
get_score <- function(ath_row, fld) {
  val <- ath_row[[fld]]
  if (is.null(val) || length(val) == 0) return(NA_real_)
  v <- suppressWarnings(as.numeric(val))
  if (is.na(v)) return(NA_real_)
  v
}

build_comparison <- function(ath_row, div_name) {
  d <- bm %>% filter(division == div_name)
  # Use sapply instead of rowwise to avoid dplyr warnings on NA scores
  d$score <- sapply(d$field_name, function(f) get_score(ath_row, f))
  d$met   <- mapply(meets_benchmark, d$score, d$cutoff, d$lower_better)
  d$pct   <- mapply(pct_of_benchmark, d$score, d$cutoff, d$lower_better)
  d$gap   <- ifelse(d$lower_better, d$score - d$cutoff, d$cutoff - d$score)
  d
}

# Three-tier performance colour — used consistently across all charts
# >= 100% : green  (#07bc0c) — meets or exceeds the standard
#  60–99% : yellow (#f1c40f) — close but not there yet
#  <= 59% : red    (#e74d3c) — needs significant work
perf_color <- function(pct, alpha = 1) {
  sapply(pct, function(p) {
    if (is.na(p))   return(sprintf("rgba(200,200,200,%.2f)", alpha))
    if (p >= 100)   return(sprintf("rgba(7,188,12,%.2f)",    alpha))
    if (p >= 60)    return(sprintf("rgba(241,196,15,%.2f)",  alpha))
    return(sprintf("rgba(231,76,60,%.2f)",   alpha))
  })
}

perf_color_solid <- function(pct) {
  sapply(pct, function(p) {
    if (is.na(p)) return("#c8c8c8")
    if (p >= 100) return("#07bc0c")
    if (p >= 60)  return("#f1c40f")
    return("#e74d3c")
  })
}
GRID <- "rgba(18,18,18,0.07)"
TXT  <- "#121212"
BG   <- "rgba(0,0,0,0)"   # transparent — lets the page background show through

# ── 6. UI ─────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  
  tags$head(tags$style(HTML("
    * { box-sizing:border-box; }
    body { font-family:sans-serif; margin:0; background-color:#fff; color:#121212; }
    .app-wrapper { max-width:1360px; margin:0 auto; padding:24px 24px 80px; }

    .header-bar {
      padding:28px 0 24px; border-bottom:1px solid #e0e0e0; margin-bottom:32px;
      display:flex; align-items:flex-end; justify-content:space-between;
      gap:20px; flex-wrap:wrap;
    }
    .header-left h2 { margin:0 0 4px; font-size:24px; font-weight:700; color:#121212; }
    .header-left p  { margin:0; font-size:13px; color:#757575; }
    .header-controls { display:flex; align-items:flex-end; gap:16px; flex-wrap:wrap; }
    .ctrl-group { display:flex; flex-direction:column; }
    .ctrl-label {
      font-size:10px; font-weight:600; color:#757575;
      text-transform:uppercase; letter-spacing:.8px; margin-bottom:5px;
    }

    select, .form-control {
      background-color:#fff !important; color:#121212 !important;
      border:1px solid #e0e0e0 !important; border-radius:6px !important;
      font-size:13px !important; font-family:sans-serif !important;
      box-shadow:0px 4px 12px rgba(0,0,0,0.1) !important;
    }
    select:focus, .form-control:focus {
      border-color:#3498db !important; outline:none !important;
      box-shadow:0 0 0 2px rgba(52,152,219,0.15) !important;
    }
    label { font-size:12px; color:#757575; font-weight:500; }

    .athlete-panel { padding-right:24px; border-right:1px solid #e0e0e0; }
    .athlete-name  { font-size:15px; font-weight:700; color:#121212; margin:0 0 16px; }
    .info-row {
      display:flex; justify-content:space-between;
      padding:8px 0; border-bottom:1px solid #f0f0f0; font-size:13px;
    }
    .info-row:last-child { border-bottom:none; }
    .info-key { color:#757575; }
    .info-val { color:#121212; font-weight:500; }

    .stat-row { padding:14px 0; border-bottom:1px solid #f0f0f0; }
    .stat-row:last-child { border-bottom:none; }
    .stat-top { display:flex; justify-content:space-between; align-items:baseline; margin-bottom:6px; }
    .stat-label { font-size:10px; font-weight:600; color:#757575; text-transform:uppercase; letter-spacing:.6px; }
    .stat-value-group { display:flex; align-items:baseline; gap:5px; }
    .stat-value { font-size:22px; font-weight:800; color:#121212; line-height:1; }
    .stat-unit  { font-size:11px; color:#757575; }
    .stat-right { text-align:right; }
    .stat-cutoff { font-size:11px; color:#757575; }
    .stat-status { font-size:12px; font-weight:600; margin-top:2px; }
    .stat-status.met    { color:#07bc0c; }
    .stat-status.warn   { color:#f1c40f; }
    .stat-status.missed { color:#e74d3c; }
    .stat-bar  { height:3px; background:#e0e0e0; border-radius:2px; }
    .stat-fill { height:3px; border-radius:2px; }

    .sec-hdr {
      display:flex; align-items:center; justify-content:space-between;
      padding:18px 0; border-bottom:1px solid #e0e0e0;
      cursor:pointer; user-select:none;
    }
    .sec-hdr:hover .sec-title { color:#3498db; }
    .sec-hdr-left { display:flex; align-items:center; gap:12px; }
    .sec-num {
      width:26px; height:26px; border-radius:50%;
      background:#121212; color:#fff;
      font-size:11px; font-weight:700;
      display:flex; align-items:center; justify-content:center; flex-shrink:0;
    }
    .sec-title { font-size:15px; font-weight:700; color:#121212; transition:color .15s; }
    .sec-arrow { font-size:11px; color:#757575; transition:transform .2s; }
    .sec-arrow.open { transform:rotate(180deg); }
    .sec-body { padding:24px 0 8px; overflow:hidden; }
    .plot-title {
      font-size:11px; font-weight:600; color:#757575;
      text-transform:uppercase; letter-spacing:.6px; margin:0 0 16px;
    }

    table.shiny-table {
      background:#fff !important; color:#121212 !important;
      border-color:#e0e0e0 !important; width:100% !important; font-size:13px;
      box-shadow:0px 4px 12px rgba(0,0,0,0.1);
    }
    table.shiny-table th {
      background:#f5f5f5 !important; color:#757575 !important;
      font-weight:600; font-size:11px; text-transform:uppercase; letter-spacing:.5px;
      border-color:#e0e0e0 !important;
    }
    table.shiny-table td { border-color:#f0f0f0 !important; }
    table.shiny-table tr:hover td { background:#f9f9f9 !important; }

    .plotly.html-widget { width:100% !important; }
    .js-plotly-plot      { width:100% !important; }
    .plot-container      { width:100% !important; }
  "))),
  
  div(class = "app-wrapper",
      
      div(class = "header-bar",
          div(class = "header-left",
              h2("Recruiting Profile"),
              p("See where your scores stand against college standards")
          ),
          div(class = "header-controls",
              div(class = "ctrl-group",
                  div(class = "ctrl-label", "Athlete"),
                  selectInput("athlete_sel", NULL,
                              choices  = setNames(athletes$username, athletes$display_name),
                              selected = athletes$username[1], width = "160px")
              ),
              div(class = "ctrl-group",
                  div(class = "ctrl-label", "Compare Against"),
                  selectInput("div_global", NULL,
                              choices = div_choices, selected = "Division 1", width = "210px")
              )
          )
      ),
      
      fluidRow(
        column(2,
               div(class = "athlete-panel",
                   div(class = "athlete-name", uiOutput("athlete_name_ui")),
                   uiOutput("athlete_info_ui")
               )
        ),
        column(10,
               
               # 1. Overview
               div(class = "sec-hdr", id = "hdr_overview",
                   div(class = "sec-hdr-left",
                       div(class = "sec-num", "1"),
                       span(class = "sec-title", "Your Overview")
                   ),
                   span(class = "sec-arrow open", id = "arr_overview", "▼")
               ),
               div(class = "sec-body", id = "body_overview",
                   fluidRow(
                     column(7,
                            p(class = "plot-title", "Skill Profile"),
                            plotlyOutput("spider_chart", height = "460px", width = "100%")
                     ),
                     column(5,
                            p(class = "plot-title", "Score Summary"),
                            uiOutput("stat_cards_ui")
                     )
                   )
               ),
               
               # 2. How Close
               div(class = "sec-hdr", id = "hdr_close",
                   div(class = "sec-hdr-left",
                       div(class = "sec-num", "2"),
                       span(class = "sec-title", "How Close Am I?")
                   ),
                   span(class = "sec-arrow", id = "arr_close", "▼")
               ),
               div(class = "sec-body", id = "body_close",
                   fluidRow(
                     column(6,
                            p(class = "plot-title", "Score vs Standard"),
                            plotlyOutput("bar_chart", height = "260px", width = "100%")
                     ),
                     column(6,
                            p(class = "plot-title", "% of Standard Reached"),
                            plotlyOutput("lollipop_chart", height = "260px", width = "100%")
                     )
                   )
               ),
               
               # 3. Progress
               div(class = "sec-hdr", id = "hdr_progress",
                   div(class = "sec-hdr-left",
                       div(class = "sec-num", "3"),
                       span(class = "sec-title", "My Progress")
                   ),
                   span(class = "sec-arrow", id = "arr_progress", "▼")
               ),
               div(class = "sec-body", id = "body_progress",
                   div(style = "display:flex;align-items:center;justify-content:space-between;margin-bottom:16px",
                       p(class = "plot-title", style = "margin:0", "Performance Trend"),
                       selectInput("trend_metric", NULL,
                                   choices = metric_choices, selected = "sprint_40yd", width = "200px")
                   ),
                   plotlyOutput("trend_chart", height = "280px", width = "100%")
               ),
               
               # 4. School Fit
               div(class = "sec-hdr", id = "hdr_schools",
                   div(class = "sec-hdr-left",
                       div(class = "sec-num", "4"),
                       span(class = "sec-title", "School Fit")
                   ),
                   span(class = "sec-arrow", id = "arr_schools", "▼")
               ),
               div(class = "sec-body", id = "body_schools",
                   p(class = "plot-title", "School Fit Heatmap"),
                   p(style = "font-size:12px;color:#757575;margin:-10px 0 16px",
                     "Green = meets the standard  |  Yellow = close  |  Red = needs work"),
                   plotlyOutput("heatmap_chart", height = "300px", width = "100%"),
                   tags$br(),
                   p(class = "plot-title", "Fit Summary"),
                   tableOutput("fit_table")
               )
        )
      )
  ),
  
  tags$script(HTML("
    function relayoutAllPlots() {
      document.querySelectorAll('.js-plotly-plot').forEach(function(p) {
        Plotly.relayout(p, {autosize: true});
      });
    }

    document.addEventListener('DOMContentLoaded', function() {

      // Collapse sections 2-4 on load
      setTimeout(function() {
        ['close','progress','schools'].forEach(function(id) {
          document.getElementById('body_' + id).style.display = 'none';
        });
      }, 150);

      // Relayout all plots a moment after any select changes (athlete or division)
      // This prevents the grey/stale chart when switching athletes with sections open
      ['athlete_sel', 'div_global'].forEach(function(selId) {
        var el = document.getElementById(selId);
        if (el) {
          el.addEventListener('change', function() {
            setTimeout(relayoutAllPlots, 300);
          });
        }
      });

      // Section toggle
      ['overview','close','progress','schools'].forEach(function(id) {
        document.getElementById('hdr_' + id).addEventListener('click', function() {
          var body  = document.getElementById('body_' + id);
          var arrow = document.getElementById('arr_' + id);
          var open  = body.style.display !== 'none';
          body.style.display = open ? 'none' : 'block';
          arrow.className = 'sec-arrow' + (open ? '' : ' open');
          if (!open) {
            setTimeout(function() {
              body.querySelectorAll('.js-plotly-plot').forEach(function(p) {
                Plotly.relayout(p, {autosize: true});
              });
            }, 80);
          }
        });
      });
    });
  "))
)

# ── 7. Server ─────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  ath     <- reactive({ athletes %>% filter(username == input$athlete_sel) })
  ath_his <- reactive({ history  %>% filter(username == input$athlete_sel) %>% arrange(test_date) })
  sel_div <- reactive({ input$div_global })
  
  output$athlete_name_ui <- renderUI({ span(ath()$display_name) })
  
  output$athlete_info_ui <- renderUI({
    a  <- ath()
    ft <- floor(a$height_in / 12); inch <- a$height_in %% 12
    ht <- if (!is.na(a$height_in)) paste0(ft, "'", inch, '"') else "—"
    wt <- if (!is.na(a$weight_lb)) paste0(a$weight_lb, " lbs") else "—"
    gy <- if (!is.na(a$grad_year)) a$grad_year else "—"
    tagList(
      div(class="info-row", span(class="info-key","Grad Year"), span(class="info-val", gy)),
      div(class="info-row", span(class="info-key","Height"),    span(class="info-val", ht)),
      div(class="info-row", span(class="info-key","Weight"),    span(class="info-val", wt))
    )
  })
  
  output$stat_cards_ui <- renderUI({
    comp <- build_comparison(ath(), sel_div())
    rows <- lapply(seq_len(nrow(comp)), function(i) {
      r      <- comp[i, ]
      # NA = truly missing field; 0 is a real score and must display
      score_missing <- is.na(r$score)
      pct_v  <- if (!is.na(r$pct)) min(r$pct, 100) / 100 else 0
      met    <- isTRUE(r$met)
      fill_c <- if (score_missing) "#e0e0e0"
      else perf_color_solid(r$pct)
      status <- if (score_missing)  "Not yet recorded"
      else if (met)       "Meets standard"
      else paste0(round(abs(r$gap), 2), " ", r$unit, " to go")
      scls   <- if (score_missing)       "stat-status missed"
      else if (met)            "stat-status met"
      else if (!is.na(r$pct) && r$pct >= 60) "stat-status warn"
      else                     "stat-status missed"
      # Display the score — 0 shows as 0, NA shows as "—"
      score_display <- if (score_missing) "—" else as.character(r$score)
      div(class = "stat-row",
          div(class = "stat-top",
              div(
                div(class = "stat-label", r$short_label),
                div(class = "stat-value-group",
                    span(class = "stat-value", score_display),
                    span(class = "stat-unit",  r$unit)
                )
              ),
              div(class = "stat-right",
                  div(class = "stat-cutoff", paste0("Cutoff: ", r$cutoff)),
                  div(class = scls, status)
              )
          ),
          div(class = "stat-bar",
              div(class = "stat-fill",
                  style = paste0("width:", round(pct_v * 100, 0), "%;background:", fill_c, ";")))
      )
    })
    do.call(tagList, rows)
  })
  
  output$spider_chart <- renderPlotly({
    c2 <- build_comparison(ath(), sel_div()) %>%
      filter(!is.na(cutoff), !is.na(score)) %>%
      mutate(pct = ifelse(is.na(pct), 0, pct))
    req(nrow(c2) > 0)
    
    cats  <- c(c2$short_label, c2$short_label[1])
    # Cap at 100 so the shape never exceeds the outer ring
    ath_r <- pmin(c(c2$pct, c2$pct[1]), 100)
    n     <- length(cats)
    
    # Colour the athlete shape by the worst-performing metric
    min_pct   <- min(c2$pct, na.rm = TRUE)
    fill_col  <- if (min_pct >= 100) "rgba(7,188,12,0.20)"
    else if (min_pct >= 60) "rgba(241,196,15,0.18)"
    else "rgba(231,76,60,0.18)"
    line_col  <- if (min_pct >= 100) "#07bc0c"
    else if (min_pct >= 60) "#f1c40f"
    else "#e74d3c"
    
    # Hover shows per-metric pct in the right colour
    hover_col <- sapply(c(c2$pct, c2$pct[1]), function(p) {
      if (is.na(p) || p < 60)  "#e74d3c"
      else if (p < 100)        "#f1c40f"
      else                     "#07bc0c"
    })
    hover_txt <- paste0(
      "<b>", cats, "</b><br>",
      round(ath_r, 1), "% of standard"
    )
    
    plot_ly(type = "scatterpolar", mode = "lines", fill = "toself") %>%
      
      # Single athlete silhouette — one diamond, no nested rings
      add_trace(
        r         = ath_r,
        theta     = cats,
        mode      = "lines",
        fillcolor = fill_col,
        line      = list(color = line_col, width = 3),
        text      = hover_txt,
        hoverinfo = "text",
        showlegend = FALSE
      ) %>%
      
      layout(
        polar = list(
          bgcolor = "#fff",
          radialaxis = list(
            visible   = TRUE,
            range     = c(0, 100),
            # Just 4 clean reference rings, no labels cluttering the chart
            tickvals  = c(25, 50, 75, 100),
            ticktext  = c("25%", "50%", "75%", "100%"),
            tickfont  = list(size = 9, color = "#bbb"),
            tickangle = 0,
            gridcolor = "rgba(0,0,0,0.10)",
            linecolor = "rgba(0,0,0,0.10)",
            showline  = FALSE
          ),
          angularaxis = list(
            tickfont  = list(size = 14, color = "#121212"),
            linecolor = "rgba(0,0,0,0.08)",
            gridcolor = "rgba(0,0,0,0.08)",
            rotation  = 90,
            direction = "clockwise"
          )
        ),
        showlegend    = FALSE,
        margin        = list(t = 80, b = 80, l = 100, r = 100),
        paper_bgcolor = BG,
        plot_bgcolor  = BG
      ) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
  })
  
  output$bar_chart <- renderPlotly({
    c2  <- build_comparison(ath(), sel_div()) %>% filter(!is.na(cutoff), !is.na(score))
    req(nrow(c2) > 0)
    clr <- perf_color(c2$pct, alpha = 0.80)
    bdr <- perf_color_solid(c2$pct)
    plot_ly() %>%
      add_trace(x = c2$cutoff, y = c2$short_label, type="bar", orientation="h",
                name = "Standard",
                marker = list(color="rgba(18,18,18,0.08)",
                              line=list(color="rgba(18,18,18,0.15)",width=1))) %>%
      add_trace(x = c2$score, y = c2$short_label, type="bar", orientation="h",
                name = "Your Score",
                marker = list(color=clr, line=list(color=bdr,width=1.5))) %>%
      layout(barmode="overlay",
             xaxis=list(title="",zeroline=FALSE,color=TXT,gridcolor=GRID),
             yaxis=list(title="",tickfont=list(size=12,color=TXT),gridcolor=GRID),
             legend=list(orientation="h", x=0, y=-0.18, font=list(color=TXT)),
             margin=list(l=10,r=10,t=10,b=70),
             paper_bgcolor=BG, plot_bgcolor=BG) %>%
      config(displayModeBar=FALSE, responsive=TRUE)
  })
  
  output$lollipop_chart <- renderPlotly({
    c2 <- build_comparison(ath(), sel_div()) %>%
      filter(!is.na(cutoff), !is.na(score)) %>%
      mutate(pct = ifelse(is.na(pct), 0, pct))
    req(nrow(c2) > 0)
    
    # Sort to match test_map order: first metric at top, last at bottom
    # plotly horizontal bars render bottom-up so we reverse test_map order
    ordered_labels <- rev(test_map$short_label)
    c2 <- c2 %>%
      mutate(short_label = factor(short_label, levels = ordered_labels)) %>%
      arrange(short_label)
    
    bar_col   <- perf_color_solid(c2$pct)
    bar_col_a <- perf_color(c2$pct, alpha = 0.85)
    x_max     <- max(ceiling(max(c2$pct, na.rm = TRUE) * 1.15 / 10) * 10, 115)
    hover_txt <- paste0(c2$short_label,"<br>",
                        round(c2$pct,1),"% of standard<br>",
                        "Your score: ",c2$score," ",c2$unit,
                        "<br>Cutoff: ",c2$cutoff," ",c2$unit)
    plot_ly() %>%
      add_segments(x=0, xend=c2$pct, y=c2$short_label, yend=c2$short_label,
                   line=list(color=bar_col_a, width=4),
                   showlegend=FALSE, hoverinfo="none") %>%
      add_trace(type="scatter", mode="markers",
                x=c2$pct, y=c2$short_label,
                marker=list(size=16, color=bar_col,
                            line=list(color="#fff", width=2.5)),
                text=hover_txt, hoverinfo="text", showlegend=FALSE) %>%
      add_segments(x=100, xend=100, y=0.5, yend=nrow(c2)+0.5,
                   line=list(color="rgba(18,18,18,0.2)",width=1.5,dash="dot"),
                   showlegend=FALSE, hoverinfo="none") %>%
      add_annotations(x=c2$pct+(x_max*0.03), y=c2$short_label,
                      text=paste0(round(c2$pct,0),"%"),
                      showarrow=FALSE,
                      font=list(size=12,color=TXT), xanchor="left") %>%
      layout(
        xaxis = list(title="", range=c(0,x_max),
                     zeroline=FALSE, showgrid=TRUE, gridcolor=GRID,
                     ticksuffix="%", color=TXT),
        yaxis = list(
          title    = "",
          # Pin exactly to the metric labels — eliminates 0.5/4.5 numeric ticks
          tickvals = as.character(c2$short_label),
          ticktext = as.character(c2$short_label),
          tickfont = list(size=12, color=TXT),
          showgrid = FALSE,
          type     = "category"
        ),
        annotations = list(list(
          x=100, y=nrow(c2)+0.5, text="Standard",
          showarrow=FALSE, font=list(size=10, color="#757575"),
          xanchor="center"
        )),
        # Match bar chart margins exactly so the two charts sit level
        margin = list(l=10, r=20, t=10, b=70),
        paper_bgcolor=BG, plot_bgcolor=BG) %>%
      config(displayModeBar=FALSE, responsive=TRUE)
  })
  
  output$trend_chart <- renderPlotly({
    hist <- ath_his()
    req(nrow(hist) >= 2)  # need at least 2 sessions to draw a trend line
    tm <- test_map %>% filter(field_name == input$trend_metric)
    c1 <- get_cutoff(bm, input$trend_metric, "Division 1")
    c2 <- get_cutoff(bm, input$trend_metric, "Division 2")
    c3 <- get_cutoff(bm, input$trend_metric, "Division 3")
    dr <- range(hist$test_date)
    scores <- hist[[input$trend_metric]]
    req(any(!is.na(scores)))
    plot_ly() %>%
      add_trace(data=hist, x=~test_date, y=~get(input$trend_metric),
                type="scatter", mode="lines+markers",
                name="Your Score",
                line=list(color="#3498db",width=2.5),
                marker=list(color="#3498db",size=8,line=list(color="#fff",width=2)),
                fill="tozeroy", fillcolor="rgba(52,152,219,0.08)") %>%
      add_segments(x=dr[1],xend=dr[2],y=c1,yend=c1,
                   line=list(color="rgba(7,188,12,0.7)",dash="dot",width=1.5),
                   name="D1 Standard") %>%
      add_segments(x=dr[1],xend=dr[2],y=c2,yend=c2,
                   line=list(color="rgba(241,196,15,0.8)",dash="dot",width=1.5),
                   name="D2 Standard") %>%
      add_segments(x=dr[1],xend=dr[2],y=c3,yend=c3,
                   line=list(color="rgba(231,76,60,0.7)",dash="dot",width=1.5),
                   name="D3 Standard") %>%
      layout(xaxis=list(title="Test Date",showgrid=FALSE,color=TXT),
             yaxis=list(title=tm$label,showgrid=TRUE,gridcolor=GRID,color=TXT),
             legend=list(orientation="h",y=-0.28,font=list(color=TXT,size=11)),
             margin=list(l=50,r=10,t=10,b=65),
             paper_bgcolor=BG, plot_bgcolor=BG) %>%
      config(displayModeBar=FALSE, responsive=TRUE)
  })
  
  output$heatmap_chart <- renderPlotly({
    a <- ath()
    mat <- do.call(rbind, lapply(seq_len(nrow(schools)), function(si) {
      sc <- schools[si,]
      sapply(test_map$field_name, function(fld) {
        cut_v <- get_cutoff(bm, fld, sc$division)
        lb    <- test_map %>% filter(field_name==fld) %>% pull(lower_better)
        pv    <- pct_of_benchmark(get_score(a, fld), cut_v, lb)
        if (is.na(pv)) 50 else pv
      })
    }))
    hover <- matrix("", nrow(schools), nrow(test_map))
    for (si in seq_len(nrow(schools)))
      for (mi in seq_len(nrow(test_map))) {
        pv <- mat[si,mi]
        hover[si,mi] <- paste0(schools$school[si]," (",schools$division[si],")\n",
                               test_map$short_label[mi],": ",round(pv,0),"% of standard")
      }
    plot_ly(z=pmin(pmax(mat,0),130),
            x=test_map$short_label,
            y=paste0(schools$school," (",schools$division,")"),
            type="heatmap", text=hover, hoverinfo="text",
            colorscale=list(
              list(0,    "#e74d3c"),   # 0%   — red
              list(0.46, "#e74d3c"),   # 59%  — red boundary
              list(0.46, "#f1c40f"),   # 60%  — yellow starts
              list(0.77, "#f1c40f"),   # 99%  — yellow boundary
              list(0.77, "#07bc0c"),   # 100% — green starts
              list(1,    "#07bc0c")    # 130% — green
            ),
            zmin=0, zmax=130, showscale=TRUE,
            colorbar=list(title="% of Standard",
                          tickvals=c(0,90,100,115,130),
                          ticktext=c("0%","90%","Cutoff","115%","130%+"),
                          tickfont=list(size=10,color=TXT),
                          titlefont=list(color=TXT))) %>%
      layout(xaxis=list(title="",tickfont=list(size=12,color=TXT)),
             yaxis=list(title="",tickfont=list(size=11,color=TXT)),
             margin=list(l=180,r=90,t=10,b=60),
             paper_bgcolor=BG) %>%
      config(displayModeBar=FALSE, responsive=TRUE)
  })
  
  output$fit_table <- renderTable({
    a <- ath()
    do.call(rbind, lapply(seq_len(nrow(schools)), function(si) {
      sc    <- schools[si,]
      n_met <- sum(sapply(test_map$field_name, function(fld) {
        cut_v <- get_cutoff(bm, fld, sc$division)
        lb    <- test_map %>% filter(field_name==fld) %>% pull(lower_better)
        isTRUE(meets_benchmark(get_score(a,fld), cut_v, lb))
      }))
      data.frame(School=sc$school, Division=sc$division,
                 Tests_Passed=paste0(n_met," out of ",nrow(test_map)),
                 Verdict=if(n_met==nrow(test_map))"Strong Fit"
                 else if(n_met>=2)"Developing" else "Needs Work",
                 stringsAsFactors=FALSE)
    }))
  }, striped=TRUE, hover=TRUE, bordered=TRUE, spacing="s", width="100%")
}

shinyApp(ui = ui, server = server)