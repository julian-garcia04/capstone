# ============================================================
#  Athlete Recruitment Profile App
#  install.packages(c("shiny","jsonlite","plotly","dplyr","tidyr"))
# ============================================================

library(shiny)
library(jsonlite)
library(plotly)
library(dplyr)
library(tidyr)

# ── PATH CONFIGURATION ────────────────────────────────────────────────────────
BENCHMARK_PATH <- "C:/capstone/core/fixtures/initial_benchmarks.json"
ATHLETE_PATH   <- NULL

# ── 1. Load & parse benchmarks ───────────────────────────────────────────────
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

`%||%` <- function(a, b) if (!is.null(a)) a else b

benchmarks <- load_benchmarks(BENCHMARK_PATH)

# ── 2. Test metadata ──────────────────────────────────────────────────────────
test_map <- data.frame(
  test_name    = c("40-Yard Dash",
                   "Vertical Jump",
                   "T-Test",
                   "Yo-Yo Intermittent Recovery Test (Beep Test)"),
  field_name   = c("sprint_40yd", "vertical_jump", "agility_t", "beep_level"),
  label        = c("40-Yard Dash (sec)", "Vertical Jump (in)",
                   "T-Test Agility (sec)", "Beep Test (level)"),
  short_label  = c("40-Yd Dash", "Vertical Jump", "T-Test", "Beep Test"),
  lower_better = c(TRUE, FALSE, TRUE, FALSE),
  unit         = c("sec", "in", "sec", "level"),
  stringsAsFactors = FALSE
)

bm <- benchmarks %>%
  filter(test_name %in% test_map$test_name) %>%
  left_join(test_map, by = "test_name") %>%
  mutate(cutoff = ifelse(lower_better, threshold_max, threshold_min)) %>%
  select(division, field_name, label, short_label, lower_better, cutoff, unit)

get_cutoff <- function(bm_df, fld, div) {
  val <- bm_df %>% filter(field_name == fld, division == div) %>% pull(cutoff)
  if (length(val) == 0) return(NA_real_) else val[1]
}

# ── 3. Load athlete data ──────────────────────────────────────────────────────
load_athletes <- function(path) {
  raw   <- fromJSON(path, simplifyDataFrame = FALSE)
  users <- Filter(function(x) x$model == "auth.user",        raw)
  aths  <- Filter(function(x) x$model == "core.athlete",     raw)
  tests <- Filter(function(x) x$model == "core.athletetest", raw)
  
  user_map <- setNames(
    sapply(users, function(u) u$fields$username),
    sapply(users, function(u) as.character(u$pk))
  )
  
  ath_rows <- lapply(aths, function(a) {
    user_pk <- as.character(a$fields$user)
    uname   <- user_map[user_pk] %||% paste0("athlete_", a$pk)
    data.frame(
      username     = uname,
      display_name = gsub("_", " ", tools::toTitleCase(uname)),
      grad_year    = a$fields$grad_year %||% NA_integer_,
      height_in    = a$fields$height_in %||% NA_real_,
      weight_lb    = a$fields$weight_lb %||% NA_real_,
      athlete_pk   = a$pk,
      stringsAsFactors = FALSE
    )
  })
  athletes_df <- do.call(rbind, ath_rows)
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
  
  latest <- hist_df %>%
    group_by(athlete_pk) %>%
    filter(test_date == max(test_date)) %>%
    slice(1) %>%
    ungroup()
  
  for (fld in test_map$field_name) {
    match_idx <- match(athletes_df$athlete_pk, latest$athlete_pk)
    athletes_df[[fld]] <- latest[[fld]][match_idx]
  }
  
  hist_df$username <- user_map[
    as.character(athletes_df$athlete_pk[
      match(hist_df$athlete_pk, athletes_df$athlete_pk)
    ])
  ]
  list(athletes = athletes_df, history = hist_df)
}

# ── Seed data ─────────────────────────────────────────────────────────────────
seed_athletes <- data.frame(
  username = c(
    "d1_player","d2_player","d3_player","hybrid_player",
    "pct_60_player","pct_80_player","pct_90_player",
    "null_all","null_partial","zero_scores",
    "speed_only","power_only","almost_d1","overachiever"
  ),
  display_name = c(
    "D1 Player","D2 Player","D3 Player","Hybrid Player",
    "60% Player","80% Player","90% Player",
    "No Scores","Partial Scores","Zero Scores",
    "Speed Only","Power Only","Almost D1","Overachiever"
  ),
  grad_year = c(2025,2026,2026,2027,2027,2026,2025,2028,2027,2027,2026,2025,2025,2025),
  height_in = c(74,71,69,73,68,70,72,71,73,69,70,76,73,75),
  weight_lb = c(195,175,160,185,155,168,180,170,178,162,158,215,188,192),
  sprint_40yd   = c(4.50,4.75,5.00,4.55,8.33,6.25,5.56,NA,4.90,4.80,4.40,6.10,5.10,4.20),
  vertical_jump = c(34.0,29.0,24.0,25.0,10.8,14.4,16.2,NA,NA,0,12.0,38.0,17.5,40.0),
  agility_t     = c(8.5,9.2,10.0,8.7,15.0,11.25,10.0,NA,9.5,9.8,11.5,11.0,9.15,7.8),
  beep_level    = c(21.0,18.0,15.0,16.0,7.8,10.4,11.7,NA,NA,0,8.0,9.0,12.5,25.0),
  athlete_pk    = 1:14,
  stringsAsFactors = FALSE
)

seed_history <- rbind(
  data.frame(
    username      = rep(c("d1_player","d2_player","d3_player","hybrid_player"), each = 3),
    athlete_pk    = rep(1:4, each = 3),
    test_date     = rep(as.Date(c("2024-06-01","2024-09-01","2025-01-01")), times = 4),
    sprint_40yd   = c(4.65,4.55,4.50, 4.90,4.80,4.75, 5.20,5.10,5.00, 4.70,4.60,4.55),
    vertical_jump = c(31,32,34, 26,28,29, 21,23,24, 22,24,25),
    agility_t     = c(8.9,8.7,8.5, 9.5,9.3,9.2, 10.5,10.2,10.0, 9.0,8.8,8.7),
    beep_level    = c(19,20,21, 16,17,18, 13,14,15, 14,15,16),
    stringsAsFactors = FALSE
  ),
  data.frame(
    username = c(
      "pct_60_player","pct_80_player","pct_90_player",
      "null_all","null_partial","zero_scores",
      "speed_only","power_only","almost_d1","overachiever"
    ),
    athlete_pk    = 5:14,
    test_date     = rep(as.Date("2025-01-01"), 10),
    sprint_40yd   = c(8.33,6.25,5.56,NA,4.90,4.80,4.40,6.10,5.10,4.20),
    vertical_jump = c(10.8,14.4,16.2,NA,NA,0,12.0,38.0,17.5,40.0),
    agility_t     = c(15.0,11.25,10.0,NA,9.5,9.8,11.5,11.0,9.15,7.8),
    beep_level    = c(7.8,10.4,11.7,NA,NA,0,8.0,9.0,12.5,25.0),
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
  if (is.na(cutoff) || is.na(score)) return(NA_real_)
  if (lower_better && score == 0)    return(NA_real_)
  if (lower_better) round((cutoff / score) * 100, 1)
  else              round((score  / cutoff) * 100, 1)
}

get_score <- function(ath_row, fld) {
  val <- ath_row[[fld]]
  if (is.null(val) || length(val) == 0) return(NA_real_)
  v <- suppressWarnings(as.numeric(val))
  if (is.na(v)) return(NA_real_)
  v
}

build_comparison <- function(ath_row, div_name) {
  d <- bm %>% filter(division == div_name)
  d$score <- sapply(d$field_name, function(f) get_score(ath_row, f))
  d$met   <- mapply(meets_benchmark, d$score, d$cutoff, d$lower_better)
  d$pct   <- mapply(pct_of_benchmark, d$score, d$cutoff, d$lower_better)
  d$gap   <- ifelse(d$lower_better, d$score - d$cutoff, d$cutoff - d$score)
  d
}

perf_color <- function(pct, alpha = 1) {
  sapply(pct, function(p) {
    if (is.na(p))  return(sprintf("rgba(200,200,200,%.2f)", alpha))
    if (p >= 100)  return(sprintf("rgba(7,188,12,%.2f)",    alpha))
    if (p >= 60)   return(sprintf("rgba(241,196,15,%.2f)",  alpha))
    return(sprintf("rgba(231,76,60,%.2f)", alpha))
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

seg_fill_color <- function(pct) {
  if (is.na(pct) || pct == 0) return("#cccccc")
  if (pct >= 100) return("#07bc0c")
  if (pct >= 60)  return("#f1c40f")
  return("#e74d3c")
}

seg_fill_opacity <- function(pct) {
  if (is.na(pct) || pct == 0) return(0.20)
  if (pct >= 100) return(0.50)
  if (pct >= 60)  return(0.55)
  return(0.60)
}

GRID <- "rgba(18,18,18,0.07)"
TXT  <- "#121212"
BG   <- "rgba(0,0,0,0)"

# ── 6. Hexagon SVG builder ────────────────────────────────────────────────────
#
# Geometry:
#   ViewBox  : 460 wide × 500 tall
#   Centre   : (230, 220)  — shifted up to leave room for legend below
#   Radius R : 110px       — generous but leaves ≥120px margin on all sides
#
# Label placement (no clipping guaranteed):
#   TOP    (270°): text at y = CY - R - 22 (name) and y - 8 (pct) — well above
#   BOTTOM  (90°): text at y = CY + R + 22 (pct) and y + 38 (name)
#   RIGHT    (0°): text starts at x = CX + R + 16, two lines stacked
#   LEFT   (180°): text ends   at x = CX - R - 16, two lines stacked
#
# Legend sits below chart area at y ≈ 420, centred horizontally
# ─────────────────────────────────────────────────────────────────────────────
build_hexagon_svg <- function(comp) {
  
  VW <- 460
  VH <- 500
  CX <- 230   # horizontal centre
  CY <- 218   # vertical centre — pushed up so legend fits cleanly below
  R  <- 110   # radius to outer ring vertex
  
  angles_deg <- c(270, 0, 90, 180)   # top, right, bottom, left
  angles_rad <- angles_deg * pi / 180
  
  vx <- CX + R * cos(angles_rad)     # outer vertices
  vy <- CY + R * sin(angles_rad)
  
  # ── Geometry helpers ────────────────────────────────────────────────────────
  fmt  <- function(x, y) paste0(round(x, 2), ",", round(y, 2))
  fmts <- function(x, y) paste0(round(x, 2), " ", round(y, 2))
  
  poly_path <- function(xs, ys) {
    paste0("M ", paste(mapply(fmt, xs, ys), collapse = " "), " Z")
  }
  
  ring_path <- function(frac) {
    poly_path(CX + R * frac * cos(angles_rad),
              CY + R * frac * sin(angles_rad))
  }
  
  # Segment from centre → left-mid → vertex → right-mid, CAPPED at 100%
  seg_path <- function(i, pct_val) {
    scale <- min(pct_val / 100, 1.0)
    prev  <- ((i - 2) %% 4) + 1
    nxt   <- (i  %% 4) + 1
    mp1x  <- (vx[prev] + vx[i]) / 2;  mp1y <- (vy[prev] + vy[i]) / 2
    mp2x  <- (vx[i] + vx[nxt])  / 2;  mp2y <- (vy[i]   + vy[nxt]) / 2
    sc    <- function(px, py) c(CX + (px - CX) * scale, CY + (py - CY) * scale)
    sm1   <- sc(mp1x, mp1y)
    sv    <- sc(vx[i], vy[i])
    sm2   <- sc(mp2x, mp2y)
    paste0("M ", fmts(CX, CY),
           " L ", fmts(sm1[1], sm1[2]),
           " L ", fmts(sv[1],  sv[2]),
           " L ", fmts(sm2[1], sm2[2]),
           " Z")
  }
  
  # ── Per-metric values ────────────────────────────────────────────────────────
  pcts   <- ifelse(is.na(comp$pct), 0, comp$pct)
  colors <- sapply(pcts, seg_fill_color)
  opacs  <- sapply(pcts, seg_fill_opacity)
  labels <- comp$short_label
  
  # Readable on white bg: darker shades of each hue
  pct_text_color <- function(p) {
    if (is.na(p) || p == 0) return("#999999")
    if (p >= 100) return("#1a8c1e")   # dark green
    if (p >= 60)  return("#9a6f00")   # dark amber
    return("#c0392b")                 # dark red
  }
  
  # ── SVG pieces ──────────────────────────────────────────────────────────────
  
  # Subtle background fill inside outer ring
  bg_fill <- sprintf('<path d="%s" fill="#f7f8fa"/>', ring_path(1.0))
  
  # Guide rings — dashed at 25/50/75, bold solid at 100%
  guide_rings <- paste(c(
    sprintf('<path d="%s" fill="none" stroke="#dedede" stroke-width="0.8" stroke-dasharray="4,3"/>',
            ring_path(0.25)),
    sprintf('<path d="%s" fill="none" stroke="#dedede" stroke-width="0.8" stroke-dasharray="4,3"/>',
            ring_path(0.50)),
    sprintf('<path d="%s" fill="none" stroke="#c0c0c0" stroke-width="1.0" stroke-dasharray="4,3"/>',
            ring_path(0.75)),
    sprintf('<path d="%s" fill="none" stroke="#3a3a3a" stroke-width="2.2"/>',
            ring_path(1.00))
  ), collapse = "\n  ")
  
  # Axis lines centre → outer vertex
  axis_lines <- paste(
    mapply(function(x, y)
      sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#d0d0d0" stroke-width="0.9"/>',
              CX, CY, round(x, 2), round(y, 2)),
      vx, vy),
    collapse = "\n  ")
  
  # Coloured segments (capped at 100%)
  segments <- paste(
    mapply(function(i, p, col, op)
      sprintf('<path d="%s" fill="%s" fill-opacity="%.2f" stroke="%s" stroke-width="1.0" stroke-opacity="0.6"/>',
              seg_path(i, p), col, op, col),
      1:4, pcts, colors, opacs),
    collapse = "\n  ")
  
  # Outer border on top of segments
  outer_border <- sprintf(
    '<path d="%s" fill="none" stroke="#3a3a3a" stroke-width="2.2"/>',
    ring_path(1.0))
  
  # Over-100% dot on vertex
  over_dots <- paste(
    mapply(function(i, p) {
      if (p <= 100) return("")
      sprintf('<circle cx="%.2f" cy="%.2f" r="7" fill="#07bc0c" stroke="white" stroke-width="2.5"/>',
              vx[i], vy[i])
    }, 1:4, pcts),
    collapse = "\n  ")
  
  # Centre dot
  centre_dot <- sprintf(
    '<circle cx="%s" cy="%s" r="3.5" fill="#aaaaaa"/>',
    CX, CY)
  
  # Ring tick labels — right of centre axis, small grey
  # Placed just to the right of each ring intersection on the top axis
  tick_labels <- paste(
    mapply(function(frac, lbl) {
      tx <- CX + 5
      ty <- CY - R * frac
      sprintf(
        '<text x="%.1f" y="%.1f" font-family="\'Inter\',sans-serif" font-size="9" fill="#b0b0b0" dominant-baseline="middle">%s</text>',
        tx, ty, lbl)
    },
    c(0.25, 0.50, 0.75, 1.00),
    c("25%", "50%", "75%", "100%")),
    collapse = "\n  ")
  
  # ── External labels ──────────────────────────────────────────────────────────
  # Rules:
  #   TOP    (i=1, ang=270): pct above name, both centred, above the vertex
  #   BOTTOM (i=3, ang=90) : pct below vertex then name below that
  #   RIGHT  (i=2, ang=0)  : pct on line 1, name on line 2, left-anchored right of vertex
  #   LEFT   (i=4, ang=180): pct on line 1, name on line 2, right-anchored left of vertex
  #
  # Safe x-positions:
  #   RIGHT label starts at x = CX + R + 16 = 230 + 110 + 16 = 356
  #     "Vertical Jump" ≈ 75px wide → ends at 431 < 460 ✓
  #   LEFT label ends at x = CX - R - 16 = 230 - 110 - 16 = 104
  #     "Beep Test" ≈ 55px wide → starts at 49 > 0 ✓
  #   TOP/BOTTOM centred at x = 230 ✓
  
  GAP <- 16   # px gap between outer vertex and nearest text edge
  
  make_label <- function(i, pct_val, lbl) {
    ang     <- angles_deg[i]
    raw_pct <- comp$pct[i]
    pct_str <- if (is.na(raw_pct)) "N/A" else paste0(round(raw_pct, 0), "%")
    pcol    <- pct_text_color(raw_pct)
    
    if (ang == 270) {
      # TOP — pct closer to chart, name further above
      px <- CX
      py_pct  <- vy[i] - GAP - 2         # pct sits just above vertex
      py_name <- py_pct - 17             # name above pct
      paste0(
        sprintf('<text x="%.1f" y="%.1f" text-anchor="middle" font-family="\'Inter\',sans-serif" font-size="11" font-weight="600" fill="#444444">%s</text>',
                px, py_name, lbl),
        "\n  ",
        sprintf('<text x="%.1f" y="%.1f" text-anchor="middle" font-family="\'Inter\',sans-serif" font-size="14" font-weight="700" fill="%s">%s</text>',
                px, py_pct, pcol, pct_str)
      )
    } else if (ang == 90) {
      # BOTTOM — pct just below vertex, name further below
      px <- CX
      py_pct  <- vy[i] + GAP + 14        # pct sits just below vertex
      py_name <- py_pct + 18             # name below pct
      paste0(
        sprintf('<text x="%.1f" y="%.1f" text-anchor="middle" font-family="\'Inter\',sans-serif" font-size="14" font-weight="700" fill="%s">%s</text>',
                px, py_pct, pcol, pct_str),
        "\n  ",
        sprintf('<text x="%.1f" y="%.1f" text-anchor="middle" font-family="\'Inter\',sans-serif" font-size="11" font-weight="600" fill="#444444">%s</text>',
                px, py_name, lbl)
      )
    } else if (ang == 0) {
      # RIGHT — left-anchored, two lines stacked
      lx <- vx[i] + GAP
      paste0(
        sprintf('<text x="%.1f" y="%.1f" text-anchor="start" dominant-baseline="middle" font-family="\'Inter\',sans-serif" font-size="14" font-weight="700" fill="%s">%s</text>',
                lx, CY - 9, pcol, pct_str),
        "\n  ",
        sprintf('<text x="%.1f" y="%.1f" text-anchor="start" dominant-baseline="middle" font-family="\'Inter\',sans-serif" font-size="11" font-weight="600" fill="#444444">%s</text>',
                lx, CY + 9, lbl)
      )
    } else {
      # LEFT — right-anchored, two lines stacked
      lx <- vx[i] - GAP
      paste0(
        sprintf('<text x="%.1f" y="%.1f" text-anchor="end" dominant-baseline="middle" font-family="\'Inter\',sans-serif" font-size="14" font-weight="700" fill="%s">%s</text>',
                lx, CY - 9, pcol, pct_str),
        "\n  ",
        sprintf('<text x="%.1f" y="%.1f" text-anchor="end" dominant-baseline="middle" font-family="\'Inter\',sans-serif" font-size="11" font-weight="600" fill="#444444">%s</text>',
                lx, CY + 9, lbl)
      )
    }
  }
  
  metric_labels <- paste(
    mapply(make_label, 1:4, pcts, labels),
    collapse = "\n  ")
  
  # ── Legend — centred below chart, at y ≈ 415 ─────────────────────────────
  # Three items side-by-side with dot + label
  # Total width ≈ 3 × 130 = 390px, centred at x=230 → starts at x=35
  legend_y  <- CY + R + 75    # well below bottom label
  legend_x  <- CX - 175       # left edge of three-item row
  
  legend <- paste0(
    # Green
    sprintf('<circle cx="%.1f" cy="%.1f" r="5" fill="#07bc0c" opacity="0.85"/>',
            legend_x + 5, legend_y),
    sprintf('<text x="%.1f" y="%.1f" font-family="\'Inter\',sans-serif" font-size="9.5" fill="#555555" dominant-baseline="middle">Meets standard (\u226510%%)</text>',
            legend_x + 15, legend_y),
    # Yellow
    sprintf('<circle cx="%.1f" cy="%.1f" r="5" fill="#f1c40f" opacity="0.9"/>',
            legend_x + 142, legend_y),
    sprintf('<text x="%.1f" y="%.1f" font-family="\'Inter\',sans-serif" font-size="9.5" fill="#555555" dominant-baseline="middle">Close (60\u201399%%)</text>',
            legend_x + 152, legend_y),
    # Red
    sprintf('<circle cx="%.1f" cy="%.1f" r="5" fill="#e74d3c" opacity="0.85"/>',
            legend_x + 270, legend_y),
    sprintf('<text x="%.1f" y="%.1f" font-family="\'Inter\',sans-serif" font-size="9.5" fill="#555555" dominant-baseline="middle">Needs work (&lt;60%%)</text>',
            legend_x + 280, legend_y)
  )
  
  # ── Assemble ────────────────────────────────────────────────────────────────
  svg_html <- sprintf(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="100%%" height="100%%">

  <!-- White background -->
  <rect width="%d" height="%d" fill="white"/>

  <!-- Inner ring fill -->
  %s

  <!-- Guide rings -->
  %s

  <!-- Axis lines -->
  %s

  <!-- Segments (capped at 100%%) -->
  %s

  <!-- Outer ring border -->
  %s

  <!-- Over-100%% dots -->
  %s

  <!-- Centre dot -->
  %s

  <!-- Ring tick labels -->
  %s

  <!-- External metric labels -->
  %s

  <!-- Legend -->
  %s

</svg>',
    VW, VH, VW, VH,
    bg_fill, guide_rings, axis_lines,
    segments, outer_border, over_dots,
    centre_dot, tick_labels, metric_labels,
    legend
  )
  
  HTML(svg_html)
}

# ── 7. UI ─────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "stylesheet",
              href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"),
    tags$style(HTML("
      * { box-sizing:border-box; }
      body { font-family:'Inter',sans-serif; margin:0; background-color:#fff; color:#121212; }
      .app-wrapper { max-width:1360px; margin:0 auto; padding:24px 24px 80px; }

      /* ── Header ── */
      .header-bar {
        padding:28px 0 24px; border-bottom:2px solid #f0f0f0; margin-bottom:32px;
        display:flex; align-items:flex-end; justify-content:space-between;
        gap:20px; flex-wrap:wrap;
      }
      .header-left { display:flex; flex-direction:column; gap:2px; }
      .header-eyebrow {
        font-size:10px; font-weight:600; letter-spacing:1.4px;
        text-transform:uppercase; color:#3498db; margin:0;
      }
      .header-left h2 {
        margin:4px 0 4px; font-size:26px; font-weight:700;
        color:#0d0d0d; letter-spacing:-0.3px;
      }
      .header-left p { margin:0; font-size:13px; color:#888888; }

      .header-controls { display:flex; align-items:flex-end; gap:16px; flex-wrap:wrap; }
      .ctrl-group { display:flex; flex-direction:column; }
      .ctrl-label {
        font-size:10px; font-weight:600; color:#888888;
        text-transform:uppercase; letter-spacing:1px; margin-bottom:6px;
      }
      select, .form-control {
        background-color:#fff !important; color:#121212 !important;
        border:1.5px solid #e0e0e0 !important; border-radius:8px !important;
        font-size:13px !important; font-family:'Inter',sans-serif !important;
        padding:8px 12px !important;
        box-shadow:0 1px 4px rgba(0,0,0,0.07) !important;
        transition:border-color .15s !important;
      }
      select:focus, .form-control:focus {
        border-color:#3498db !important; outline:none !important;
        box-shadow:0 0 0 3px rgba(52,152,219,0.12) !important;
      }

      /* ── Athlete panel ── */
      .athlete-panel { padding-right:24px; border-right:2px solid #f0f0f0; }
      .athlete-name {
        font-size:15px; font-weight:700; color:#0d0d0d;
        margin:0 0 16px; letter-spacing:-0.2px;
      }
      .info-row {
        display:flex; justify-content:space-between; align-items:center;
        padding:9px 0; border-bottom:1px solid #f4f4f4; font-size:13px;
      }
      .info-row:last-child { border-bottom:none; }
      .info-key { color:#999999; font-weight:500; }
      .info-val { color:#121212; font-weight:600; }

      /* ── Stat cards ── */
      .stat-row {
        padding:14px 0 14px 12px;
        border-bottom:1px solid #f4f4f4;
        border-left:3px solid transparent;
        margin-left:-12px;
        transition:border-color .2s;
      }
      .stat-row:last-child { border-bottom:none; }
      .stat-row.color-met    { border-left-color:#07bc0c; }
      .stat-row.color-warn   { border-left-color:#f1c40f; }
      .stat-row.color-missed { border-left-color:#e74d3c; }
      .stat-top { display:flex; justify-content:space-between; align-items:baseline; margin-bottom:8px; }
      .stat-label {
        font-size:10px; font-weight:700; color:#888888;
        text-transform:uppercase; letter-spacing:.8px;
      }
      .stat-value-group { display:flex; align-items:baseline; gap:4px; }
      .stat-value { font-size:24px; font-weight:800; color:#0d0d0d; line-height:1; }
      .stat-unit  { font-size:11px; color:#aaaaaa; font-weight:500; }
      .stat-right { text-align:right; }
      .stat-cutoff {
        font-size:11px; color:#aaaaaa; font-weight:500;
        background:#f5f5f5; padding:2px 7px; border-radius:4px;
        display:inline-block; margin-bottom:4px;
      }
      .stat-status { font-size:12px; font-weight:600; margin-top:2px; }
      .stat-status.met    { color:#1a8c1e; }
      .stat-status.warn   { color:#9a6f00; }
      .stat-status.missed { color:#c0392b; }
      .stat-bar  { height:4px; background:#eeeeee; border-radius:2px; }
      .stat-fill { height:4px; border-radius:2px; }

      /* ── Hexagon chart card ── */
      .hex-chart-wrap {
        display:flex; align-items:center; justify-content:center;
        width:100%; padding:4px 0 12px;
      }
      .hex-chart-inner {
        width:100%; max-width:420px;
        aspect-ratio:460/500;
        background:#ffffff;
        border:1.5px solid #eeeeee;
        border-radius:14px;
        box-shadow:0 2px 12px rgba(0,0,0,0.06);
        overflow:hidden;
      }

      /* ── Section headers ── */
      .sec-hdr {
        display:flex; align-items:center; justify-content:space-between;
        padding:18px 0; border-bottom:1px solid #f0f0f0;
        cursor:pointer; user-select:none;
      }
      .sec-hdr:hover .sec-title { color:#3498db; }
      .sec-hdr-left { display:flex; align-items:center; gap:12px; }
      .sec-num {
        width:28px; height:28px; border-radius:50%;
        background:#3498db; color:#fff;
        font-size:12px; font-weight:700;
        display:flex; align-items:center; justify-content:center; flex-shrink:0;
      }
      .sec-title {
        font-size:15px; font-weight:700; color:#0d0d0d;
        letter-spacing:-0.1px; transition:color .15s;
      }
      .sec-arrow { font-size:10px; color:#bbbbbb; transition:transform .2s; }
      .sec-arrow.open { transform:rotate(180deg); }
      .sec-body { padding:24px 0 8px; overflow:hidden; }
      .plot-title {
        font-size:10px; font-weight:700; color:#aaaaaa;
        text-transform:uppercase; letter-spacing:1.1px; margin:0 0 16px;
      }

      /* ── Tables ── */
      table.shiny-table {
        background:#fff !important; color:#121212 !important;
        border-color:#eeeeee !important; width:100% !important;
        font-size:13px; border-radius:8px; overflow:hidden;
        box-shadow:0 1px 6px rgba(0,0,0,0.07);
        font-family:'Inter',sans-serif !important;
      }
      table.shiny-table th {
        background:#f8f8f8 !important; color:#888888 !important;
        font-weight:700; font-size:10px; text-transform:uppercase;
        letter-spacing:.8px; border-color:#eeeeee !important;
        padding:10px 12px !important;
      }
      table.shiny-table td {
        border-color:#f4f4f4 !important;
        padding:10px 12px !important;
      }
      table.shiny-table tr:hover td { background:#fafafa !important; }

      .plotly.html-widget { width:100% !important; }
      .js-plotly-plot      { width:100% !important; }
      .plot-container      { width:100% !important; }
    "))
  ),
  
  div(class = "app-wrapper",
      
      # ── Header ────────────────────────────────────────────────────────────────
      div(class = "header-bar",
          div(class = "header-left",
              p(class = "header-eyebrow", "Athlete Dashboard"),
              h2("Recruiting Profile"),
              p("See where your scores stand against college standards")
          ),
          div(class = "header-controls",
              div(class = "ctrl-group",
                  div(class = "ctrl-label", "Athlete"),
                  selectInput("athlete_sel", NULL,
                              choices  = setNames(athletes$username, athletes$display_name),
                              selected = athletes$username[1], width = "180px")
              ),
              div(class = "ctrl-group",
                  div(class = "ctrl-label", "Compare Against"),
                  selectInput("div_global", NULL,
                              choices = div_choices, selected = "Division 1", width = "220px")
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
                            div(class = "hex-chart-wrap",
                                div(class = "hex-chart-inner",
                                    uiOutput("hexagon_chart")
                                )
                            )
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
                   p(style = "font-size:12px;color:#aaaaaa;margin:-10px 0 16px",
                     "Green = meets the standard  \u00b7  Yellow = close  \u00b7  Red = needs work"),
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
        Plotly.relayout(p, { autosize: true });
      });
    }
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(function() {
        ['close','progress','schools'].forEach(function(id) {
          document.getElementById('body_' + id).style.display = 'none';
        });
      }, 150);
      ['athlete_sel','div_global'].forEach(function(selId) {
        var el = document.getElementById(selId);
        if (el) el.addEventListener('change', function() {
          setTimeout(relayoutAllPlots, 300);
        });
      });
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
                Plotly.relayout(p, { autosize: true });
              });
            }, 80);
          }
        });
      });
    });
  "))
)

# ── 8. Server ─────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  ath     <- reactive({ athletes %>% filter(username == input$athlete_sel) })
  ath_his <- reactive({ history  %>% filter(username == input$athlete_sel) %>% arrange(test_date) })
  sel_div <- reactive({ input$div_global })
  
  output$athlete_name_ui <- renderUI({ span(ath()$display_name) })
  
  output$athlete_info_ui <- renderUI({
    a    <- ath()
    ft   <- floor(a$height_in / 12); inch <- a$height_in %% 12
    ht   <- if (!is.na(a$height_in)) paste0(ft, "'", inch, '"') else "\u2014"
    wt   <- if (!is.na(a$weight_lb)) paste0(a$weight_lb, " lbs") else "\u2014"
    gy   <- if (!is.na(a$grad_year)) a$grad_year else "\u2014"
    tagList(
      div(class="info-row", span(class="info-key","Grad Year"), span(class="info-val", gy)),
      div(class="info-row", span(class="info-key","Height"),    span(class="info-val", ht)),
      div(class="info-row", span(class="info-key","Weight"),    span(class="info-val", wt))
    )
  })
  
  output$stat_cards_ui <- renderUI({
    comp <- build_comparison(ath(), sel_div())
    rows <- lapply(seq_len(nrow(comp)), function(i) {
      r             <- comp[i, ]
      score_missing <- is.na(r$score)
      pct_v         <- if (!is.na(r$pct)) min(r$pct, 100) / 100 else 0
      met           <- isTRUE(r$met)
      fill_c        <- if (score_missing) "#e0e0e0" else perf_color_solid(r$pct)
      
      # Left-border class
      border_cls    <- if (score_missing)                       "color-missed"
      else if (met)                            "color-met"
      else if (!is.na(r$pct) && r$pct >= 60)  "color-warn"
      else                                     "color-missed"
      
      status        <- if (score_missing) "Not yet recorded"
      else if (met)      "Meets standard"
      else paste0(round(abs(r$gap), 2), " ", r$unit, " to go")
      scls          <- if (score_missing)                       "stat-status missed"
      else if (met)                            "stat-status met"
      else if (!is.na(r$pct) && r$pct >= 60)  "stat-status warn"
      else                                     "stat-status missed"
      score_display <- if (score_missing) "\u2014" else as.character(r$score)
      
      div(class = paste("stat-row", border_cls),
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
                  style = paste0("width:", round(pct_v * 100, 0),
                                 "%;background:", fill_c, ";")))
      )
    })
    do.call(tagList, rows)
  })
  
  # ── Hexagon ───────────────────────────────────────────────────────────────
  output$hexagon_chart <- renderUI({
    comp <- build_comparison(ath(), sel_div()) %>%
      mutate(pct = ifelse(is.na(pct), 0, pct))
    comp <- test_map %>%
      select(field_name, short_label) %>%
      left_join(comp, by = c("field_name", "short_label"))
    req(nrow(comp) == 4)
    build_hexagon_svg(comp)
  })
  
  # ── Bar chart ─────────────────────────────────────────────────────────────
  output$bar_chart <- renderPlotly({
    c2 <- build_comparison(ath(), sel_div()) %>% filter(!is.na(cutoff), !is.na(score))
    req(nrow(c2) > 0)
    clr <- perf_color(c2$pct, alpha = 0.80)
    bdr <- perf_color_solid(c2$pct)
    plot_ly() %>%
      add_trace(x = c2$cutoff, y = c2$short_label, type = "bar", orientation = "h",
                name = "Standard",
                marker = list(color = "rgba(18,18,18,0.08)",
                              line  = list(color = "rgba(18,18,18,0.15)", width = 1))) %>%
      add_trace(x = c2$score, y = c2$short_label, type = "bar", orientation = "h",
                name = "Your Score",
                marker = list(color = clr, line = list(color = bdr, width = 1.5))) %>%
      layout(barmode = "overlay",
             xaxis   = list(title = "", zeroline = FALSE, color = TXT, gridcolor = GRID),
             yaxis   = list(title = "", tickfont = list(size = 12, color = TXT, family = "Inter"), gridcolor = GRID),
             legend  = list(orientation = "h", x = 0, y = -0.18, font = list(color = TXT, family = "Inter")),
             margin  = list(l = 10, r = 10, t = 10, b = 70),
             paper_bgcolor = BG, plot_bgcolor = BG) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
  })
  
  # ── Lollipop ──────────────────────────────────────────────────────────────
  output$lollipop_chart <- renderPlotly({
    c2 <- build_comparison(ath(), sel_div()) %>%
      filter(!is.na(cutoff), !is.na(score)) %>%
      mutate(pct = ifelse(is.na(pct), 0, pct))
    req(nrow(c2) > 0)
    
    ordered_labels <- rev(test_map$short_label)
    c2 <- c2 %>%
      mutate(short_label = factor(short_label, levels = ordered_labels)) %>%
      arrange(short_label)
    
    bar_col   <- perf_color_solid(c2$pct)
    bar_col_a <- perf_color(c2$pct, alpha = 0.85)
    x_max     <- max(ceiling(max(c2$pct, na.rm = TRUE) * 1.15 / 10) * 10, 115)
    hover_txt <- paste0(c2$short_label, "<br>",
                        round(c2$pct, 1), "% of standard<br>",
                        "Score: ", c2$score, " ", c2$unit,
                        "<br>Cutoff: ", c2$cutoff, " ", c2$unit)
    
    plot_ly() %>%
      add_segments(x = 0, xend = c2$pct, y = c2$short_label, yend = c2$short_label,
                   line = list(color = bar_col_a, width = 4),
                   showlegend = FALSE, hoverinfo = "none") %>%
      add_trace(type = "scatter", mode = "markers",
                x = c2$pct, y = c2$short_label,
                marker = list(size = 16, color = bar_col,
                              line = list(color = "#fff", width = 2.5)),
                text = hover_txt, hoverinfo = "text", showlegend = FALSE) %>%
      add_segments(x = 100, xend = 100, y = 0.5, yend = nrow(c2) + 0.5,
                   line = list(color = "rgba(18,18,18,0.2)", width = 1.5, dash = "dot"),
                   showlegend = FALSE, hoverinfo = "none") %>%
      add_annotations(x = c2$pct + (x_max * 0.03), y = c2$short_label,
                      text = paste0(round(c2$pct, 0), "%"),
                      showarrow = FALSE,
                      font = list(size = 12, color = TXT, family = "Inter"),
                      xanchor = "left") %>%
      layout(
        xaxis = list(title = "", range = c(0, x_max),
                     zeroline = FALSE, showgrid = TRUE, gridcolor = GRID,
                     ticksuffix = "%", color = TXT),
        yaxis = list(title    = "",
                     tickvals = as.character(c2$short_label),
                     ticktext = as.character(c2$short_label),
                     tickfont = list(size = 12, color = TXT, family = "Inter"),
                     showgrid = FALSE, type = "category"),
        annotations   = list(list(x = 100, y = nrow(c2) + 0.5, text = "Standard",
                                  showarrow = FALSE,
                                  font = list(size = 10, color = "#aaaaaa", family = "Inter"),
                                  xanchor = "center")),
        margin        = list(l = 10, r = 20, t = 10, b = 70),
        paper_bgcolor = BG, plot_bgcolor = BG) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
  })
  
  # ── Trend ─────────────────────────────────────────────────────────────────
  output$trend_chart <- renderPlotly({
    hist <- ath_his()
    req(nrow(hist) >= 2)
    tm <- test_map %>% filter(field_name == input$trend_metric)
    c1 <- get_cutoff(bm, input$trend_metric, "Division 1")
    c2 <- get_cutoff(bm, input$trend_metric, "Division 2")
    c3 <- get_cutoff(bm, input$trend_metric, "Division 3")
    dr <- range(hist$test_date)
    req(any(!is.na(hist[[input$trend_metric]])))
    plot_ly() %>%
      add_trace(data = hist, x = ~test_date, y = ~get(input$trend_metric),
                type = "scatter", mode = "lines+markers", name = "Your Score",
                line   = list(color = "#3498db", width = 2.5),
                marker = list(color = "#3498db", size = 8, line = list(color = "#fff", width = 2)),
                fill = "tozeroy", fillcolor = "rgba(52,152,219,0.08)") %>%
      add_segments(x = dr[1], xend = dr[2], y = c1, yend = c1,
                   line = list(color = "rgba(7,188,12,0.7)",   dash = "dot", width = 1.5), name = "D1") %>%
      add_segments(x = dr[1], xend = dr[2], y = c2, yend = c2,
                   line = list(color = "rgba(241,196,15,0.8)", dash = "dot", width = 1.5), name = "D2") %>%
      add_segments(x = dr[1], xend = dr[2], y = c3, yend = c3,
                   line = list(color = "rgba(231,76,60,0.7)",  dash = "dot", width = 1.5), name = "D3") %>%
      layout(xaxis  = list(title = "Test Date", showgrid = FALSE, color = TXT),
             yaxis  = list(title = tm$label, showgrid = TRUE, gridcolor = GRID, color = TXT),
             legend = list(orientation = "h", y = -0.28, font = list(color = TXT, size = 11, family = "Inter")),
             margin = list(l = 50, r = 10, t = 10, b = 65),
             paper_bgcolor = BG, plot_bgcolor = BG) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
  })
  
  # ── Heatmap ───────────────────────────────────────────────────────────────
  output$heatmap_chart <- renderPlotly({
    a <- ath()
    mat <- do.call(rbind, lapply(seq_len(nrow(schools)), function(si) {
      sc <- schools[si, ]
      sapply(test_map$field_name, function(fld) {
        cut_v <- get_cutoff(bm, fld, sc$division)
        lb    <- test_map %>% filter(field_name == fld) %>% pull(lower_better)
        pv    <- pct_of_benchmark(get_score(a, fld), cut_v, lb)
        if (is.na(pv)) 50 else pv
      })
    }))
    hover <- matrix("", nrow(schools), nrow(test_map))
    for (si in seq_len(nrow(schools)))
      for (mi in seq_len(nrow(test_map)))
        hover[si, mi] <- paste0(schools$school[si], " (", schools$division[si], ")\n",
                                test_map$short_label[mi], ": ",
                                round(mat[si, mi], 0), "% of standard")
    plot_ly(z          = pmin(pmax(mat, 0), 130),
            x          = test_map$short_label,
            y          = paste0(schools$school, " (", schools$division, ")"),
            type       = "heatmap", text = hover, hoverinfo = "text",
            colorscale = list(
              list(0,    "#e74d3c"), list(0.46, "#e74d3c"),
              list(0.46, "#f1c40f"), list(0.77, "#f1c40f"),
              list(0.77, "#07bc0c"), list(1,    "#07bc0c")
            ),
            zmin = 0, zmax = 130, showscale = TRUE,
            colorbar = list(title     = "% of Standard",
                            tickvals  = c(0, 90, 100, 115, 130),
                            ticktext  = c("0%","90%","Cutoff","115%","130%+"),
                            tickfont  = list(size = 10, color = TXT),
                            titlefont = list(color = TXT))) %>%
      layout(xaxis = list(title = "", tickfont = list(size = 12, color = TXT)),
             yaxis = list(title = "", tickfont = list(size = 11, color = TXT)),
             margin        = list(l = 180, r = 90, t = 10, b = 60),
             paper_bgcolor = BG) %>%
      config(displayModeBar = FALSE, responsive = TRUE)
  })
  
  # ── Fit table ─────────────────────────────────────────────────────────────
  output$fit_table <- renderTable({
    a <- ath()
    do.call(rbind, lapply(seq_len(nrow(schools)), function(si) {
      sc    <- schools[si, ]
      n_met <- sum(sapply(test_map$field_name, function(fld) {
        cut_v <- get_cutoff(bm, fld, sc$division)
        lb    <- test_map %>% filter(field_name == fld) %>% pull(lower_better)
        isTRUE(meets_benchmark(get_score(a, fld), cut_v, lb))
      }))
      data.frame(
        School       = sc$school,
        Division     = sc$division,
        Tests_Passed = paste0(n_met, " out of ", nrow(test_map)),
        Verdict      = if (n_met == nrow(test_map)) "Strong Fit"
        else if (n_met >= 2)          "Developing"
        else                          "Needs Work",
        stringsAsFactors = FALSE
      )
    }))
  }, striped = TRUE, hover = TRUE, bordered = TRUE, spacing = "s", width = "100%")
}

shinyApp(ui = ui, server = server)