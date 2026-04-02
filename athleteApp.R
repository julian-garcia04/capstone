# ============================================================
#  Athlete Recruitment Profile App
#
#  Install once in Console:
#  install.packages(c("shiny","jsonlite","plotly","dplyr","tidyr"))
# ============================================================

library(shiny)
library(jsonlite)
library(plotly)
library(dplyr)
library(tidyr)

# ── 1. Load benchmarks ────────────────────────────────────────────────────────
JSON_PATH <- "C:/capstone/core/fixtures/initial_benchmarks.json"

raw <- fromJSON(JSON_PATH, simplifyDataFrame = FALSE)
benchmarks_list <- lapply(raw, function(x) {
  data.frame(
    division      = x$fields$division,
    test_name     = x$fields$test_name,
    category      = x$fields$category,
    threshold_min = ifelse(is.null(x$fields$threshold_min), NA_real_, x$fields$threshold_min),
    threshold_max = ifelse(is.null(x$fields$threshold_max), NA_real_, x$fields$threshold_max),
    stringsAsFactors = FALSE
  )
})
benchmarks <- do.call(rbind, benchmarks_list)

# ── 2. Test metadata ──────────────────────────────────────────────────────────
test_map <- data.frame(
  test_name    = c("40-Yard Dash", "Vertical Jump", "T-Test",
                   "Yo-Yo Intermittent Recovery Test (Beep Test)"),
  field_name   = c("sprint_40yd", "vertical_jump", "agility_t", "beep_level"),
  label        = c("40-Yard Dash (sec)", "Vertical Jump (in)",
                   "T-Test Agility (sec)", "Beep Test (level)"),
  short_label  = c("40-Yd Dash", "Vertical Jump", "T-Test", "Beep Test"),
  lower_better = c(TRUE, FALSE, TRUE, FALSE),
  gauge_min    = c(6.0, 10.0, 12.0,  5.0),
  gauge_max    = c(4.2, 38.0,  7.5, 23.0),
  unit         = c("sec", "in", "sec", "level"),
  stringsAsFactors = FALSE
)

bm <- benchmarks %>%
  filter(test_name %in% test_map$test_name) %>%
  left_join(test_map, by = "test_name") %>%
  mutate(cutoff = ifelse(lower_better, threshold_max, threshold_min)) %>%
  select(division, field_name, label, short_label,
         lower_better, cutoff, gauge_min, gauge_max, unit)

get_cutoff <- function(bm_df, fld, div) {
  bm_df %>% filter(field_name == fld, division == div) %>% pull(cutoff)
}

# ── 3. Athletes ───────────────────────────────────────────────────────────────
athletes <- data.frame(
  username      = c("d1_player","d2_player","d3_player","hybrid_player"),
  display_name  = c("D1 Player","D2 Player","D3 Player","Hybrid Player"),
  grad_year     = c(2025, 2026, 2026, 2027),
  height_in     = c(74, 71, 69, 73),
  weight_lb     = c(195, 175, 160, 185),
  sprint_40yd   = c(4.50, 4.75, 5.00, 4.55),
  vertical_jump = c(34.0, 29.0, 24.0, 25.0),
  agility_t     = c(8.5,  9.2, 10.0,  8.7),
  beep_level    = c(21.0, 18.0, 15.0, 16.0),
  stringsAsFactors = FALSE
)

# ── 4. Test history ───────────────────────────────────────────────────────────
test_history <- data.frame(
  username      = rep(c("d1_player","d2_player","d3_player","hybrid_player"), each = 3),
  test_date     = rep(as.Date(c("2024-06-01","2024-09-01","2025-01-01")), times = 4),
  sprint_40yd   = c(4.65,4.55,4.50, 4.90,4.80,4.75, 5.20,5.10,5.00, 4.70,4.60,4.55),
  vertical_jump = c(31,  32,  34,   26,  28,  29,   21,  23,  24,   22,  24,  25),
  agility_t     = c(8.9, 8.7, 8.5,  9.5, 9.3, 9.2, 10.5,10.2,10.0,  9.0, 8.8, 8.7),
  beep_level    = c(19,  20,  21,   16,  17,  18,   13,  14,  15,   14,  15,  16),
  stringsAsFactors = FALSE
)

# ── 5. Schools ────────────────────────────────────────────────────────────────
schools <- data.frame(
  school   = c("State University","City College","Tech Institute",
               "Riverside U","Lakewood College","Northern State"),
  division = c("Division 1","Division 1","Division 2",
               "Division 2","Division 3","Division 3"),
  stringsAsFactors = FALSE
)

divisions <- c("Division 1","Division 2","Division 3")

# ── 6. Helpers ────────────────────────────────────────────────────────────────
meets_benchmark <- function(score, cutoff, lower_better) {
  if (is.na(cutoff) || is.na(score)) return(NA)
  if (lower_better) score <= cutoff else score >= cutoff
}

pct_of_benchmark <- function(score, cutoff, lower_better) {
  if (is.na(cutoff) || is.na(score)) return(NA_real_)
  if (lower_better) round((cutoff / score) * 100, 1)
  else              round((score  / cutoff) * 100, 1)
}

get_score <- function(ath_row, fld) as.numeric(ath_row[[fld]])

build_comparison <- function(ath_row, div_name) {
  d <- bm %>% filter(division == div_name)
  d %>% rowwise() %>% mutate(
    score = get_score(ath_row, field_name),
    met   = meets_benchmark(score, cutoff, lower_better),
    pct   = pct_of_benchmark(score, cutoff, lower_better),
    gap   = ifelse(lower_better, score - cutoff, cutoff - score)
  ) %>% ungroup()
}

# ── 7. UI ─────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  
  tags$head(tags$style(HTML("

    body {
      font-family: 'Segoe UI', sans-serif;
      margin: 0;
      background-color: #f0f2f5;
    }

    .app-wrapper {
      max-width: 1400px;
      margin: 0 auto;
      padding: 18px 18px 40px;
    }

    .header-bar {
      background: white;
      color: #111;
      padding: 20px 28px;
      border-radius: 10px;
      margin-bottom: 20px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.08);
      border-bottom: 2px solid #e8e8e8;
    }
    .header-bar h2 { margin: 0; font-size: 22px; font-weight: 700; color: #111; }
    .header-bar p  { margin: 5px 0 0; font-size: 13px; color: #888; }

    /* ── Standard card ── */
    .card {
      background: white;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 16px;
      box-shadow: 0 1px 6px rgba(0,0,0,0.10);
    }
    .card-title {
      font-size: 13px;
      font-weight: 700;
      color: #111;
      margin: 0 0 4px;
    }
    .card-sub {
      font-size: 12px;
      color: #999;
      margin: 0 0 16px;
    }

    /* ── Stat mini-cards on overview (image 2 style) ── */
    .stat-mini {
      background: #f7f8fa;
      border-radius: 10px;
      padding: 14px 16px;
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .stat-mini-left  { display: flex; flex-direction: column; }
    .stat-mini-label { font-size: 11px; color: #888; text-transform: uppercase; letter-spacing: .5px; margin-bottom: 3px; }
    .stat-mini-value { font-size: 26px; font-weight: 800; color: #111; line-height: 1; }
    .stat-mini-unit  { font-size: 12px; color: #888; margin-top: 2px; }
    .stat-mini-right { text-align: right; }
    .stat-mini-cutoff { font-size: 11px; color: #aaa; }
    .stat-mini-status { font-size: 12px; font-weight: 700; margin-top: 3px; }
    .stat-mini-status.met    { color: #1db954; }
    .stat-mini-status.missed { color: #e74c3c; }
    .stat-mini-bar {
      height: 4px;
      border-radius: 2px;
      background: #e8e8e8;
      margin-top: 8px;
      overflow: hidden;
    }
    .stat-mini-fill {
      height: 4px;
      border-radius: 2px;
    }

    /* ── Sidebar score rows ── */
    .score-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 10px 14px;
      border-radius: 8px;
      margin-bottom: 8px;
      background: #f8f9fa;
    }
    .score-row.met    { border-left: 4px solid #1db954; }
    .score-row.missed { border-left: 4px solid #e74c3c; }
    .score-label { font-size: 12px; color: #666; margin-bottom: 2px; }
    .score-val   { font-size: 19px; font-weight: 800; color: #111; }
    .score-cut   { font-size: 11px; color: #aaa; }

    /* ── Tabs ── */
    .nav-tabs { border-bottom: 1px solid #e0e0e0; margin-bottom: 4px; }
    .nav-tabs > li > a {
      color: #777; font-weight: 600; font-size: 13px;
      border: none; border-radius: 0; padding: 10px 16px;
    }
    .nav-tabs > li.active > a {
      color: #111;
      border-bottom: 2px solid #111;
      background: transparent;
    }
    .nav-tabs > li > a:hover { background: transparent; color: #333; }

    /* ── Scorecard tiles  ── */
    .tile-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:12px; }
    .tile { background:#f7f8fa; border-radius:10px; padding:16px 18px; border-top:4px solid #e0e0e0; }
    .tile.met    { border-top-color:#1db954; }
    .tile.missed { border-top-color:#e74c3c; }
    .tile-metric { font-size:11px; color:#888; text-transform:uppercase; letter-spacing:.5px; margin-bottom:6px; }
    .tile-score  { font-size:36px; font-weight:800; color:#111; line-height:1; }
    .tile-unit   { font-size:12px; color:#aaa; margin-bottom:10px; }
    .tile-div    { font-size:12px; font-weight:700; color:#555; }
    .tile-gap    { font-size:11px; color:#aaa; margin-top:3px; }

    /* ── Percentile rows ── */
    .pct-row { padding: 10px 0; border-bottom: 1px solid #f0f0f0; }
    .pct-row:last-child { border-bottom: none; }
    .pct-metric-name { font-size: 13px; font-weight: 700; color: #222; margin-bottom: 6px; }
    .pct-score-line  { font-size: 11px; color: #888; margin-top: 5px; }

    select, .form-control { border-radius: 6px !important; font-size: 13px !important; }
    label { font-size: 13px; color: #555; font-weight: 600; }

  "))),
  
  div(class = "app-wrapper",
      
      div(class = "header-bar",
          h2("Athlete Recruitment Profile"),
          p("Compare your tested scores against D1, D2, and D3 standards")
      ),
      
      fluidRow(
        
        # ── Sidebar ───────────────────────────────────────────────────────────────
        column(3,
               div(class = "card",
                   p(class = "card-title", "Select Athlete"),
                   selectInput("athlete_sel", NULL,
                               choices  = setNames(athletes$username, athletes$display_name),
                               selected = "d1_player", width = "100%")
               ),
               div(class = "card",
                   p(class = "card-title", "Athlete Info"),
                   uiOutput("athlete_info_ui")
               ),
               div(class = "card",
                   p(class = "card-title", "D1 Score Card"),
                   uiOutput("score_cards_ui")
               )
        ),
        
        # ── Main panel ────────────────────────────────────────────────────────────
        column(9,
               tabsetPanel(id = "main_tabs",
                           
                           # ── Overview ──────────────────────────────────────────────────────────
                           tabPanel("Overview", br(),
                                    
                                    # Row 1: Spider (large left) + stat mini-cards (right column)
                                    fluidRow(
                                      column(7,
                                             div(class = "card",
                                                 p(class = "card-title", "Performance Profile"),
                                                 p(class = "card-sub",   "% of division standard per metric"),
                                                 selectInput("spider_div", NULL,
                                                             choices = divisions, selected = "Division 1",
                                                             width = "180px"),
                                                 plotlyOutput("spider_chart", height = "420px")
                                             )
                                      ),
                                      column(5,
                                             # Each metric gets its own mini stat card — image 2 style
                                             uiOutput("stat_cards_ui")
                                      )
                                    ),
                                    
                                    # ── Option A: Scorecard tiles ──────────────────────────────────────
                                    div(class = "card",
                                        p(class = "card-title", "Scorecard Tiles"),
                                        p(style = "font-size:11px;color:#aaa;margin:-2px 0 14px",
                                          "Big number, division level, and gap at a glance"),
                                        uiOutput("scorecard_tiles_ui")
                                    ),
                                    
                                    # ── Option B: Progress rings ───────────────────────────────────────
                                    div(class = "card",
                                        p(class = "card-title", "Progress Rings"),
                                        p(style = "font-size:11px;color:#aaa;margin:-2px 0 14px",
                                          "% of D1 standard achieved per metric"),
                                        fluidRow(
                                          column(3, plotlyOutput("ring_1", height = "180px")),
                                          column(3, plotlyOutput("ring_2", height = "180px")),
                                          column(3, plotlyOutput("ring_3", height = "180px")),
                                          column(3, plotlyOutput("ring_4", height = "180px"))
                                        )
                                    ),
                                    
                                    # ── Option C: Bullet charts ────────────────────────────────────────
                                    div(class = "card",
                                        p(class = "card-title", "Bullet Charts"),
                                        p(style = "font-size:11px;color:#aaa;margin:-2px 0 14px",
                                          "Your score plotted against the D3 / D2 / D1 range"),
                                        plotlyOutput("bullet_chart", height = "220px")
                                    ),
                                    
                                    # Row 3: Percentile spectrum full width
                                    div(class = "card",
                                        p(class = "card-title", "Score Spectrum"),
                                        p(style = "font-size:11px;color:#aaa;margin:-2px 0 14px",
                                          "Dot shows your score within the D3 to D1 range"),
                                        uiOutput("percentile_ui")
                                    )
                           ),
                           
                           # ── Metric Breakdown ──────────────────────────────────────────────────
                           tabPanel("Metric Breakdown", br(),
                                    fluidRow(
                                      column(7,
                                             div(class = "card",
                                                 p(class = "card-title", "Score vs Division Cutoff"),
                                                 selectInput("bar_div", "Division",
                                                             choices = divisions, selected = "Division 1",
                                                             width = "100%"),
                                                 plotlyOutput("bar_chart", height = "300px")
                                             )
                                      ),
                                      column(5,
                                             div(class = "card",
                                                 p(class = "card-title", "Distance From Cutoff"),
                                                 selectInput("gap_div", "Division",
                                                             choices = divisions, selected = "Division 1",
                                                             width = "100%"),
                                                 plotlyOutput("gap_chart", height = "300px")
                                             )
                                      )
                                    )
                           ),
                           
                           # ── Progress Over Time ────────────────────────────────────────────────
                           tabPanel("Progress Over Time", br(),
                                    div(class = "card",
                                        p(class = "card-title", "Single Metric Trend"),
                                        fluidRow(
                                          column(6,
                                                 selectInput("trend_metric", "Metric",
                                                             choices = setNames(test_map$field_name, test_map$label),
                                                             width = "100%")
                                          ),
                                          column(6,
                                                 selectInput("trend_div", "Division Benchmark",
                                                             choices = divisions, selected = "Division 1",
                                                             width = "100%")
                                          )
                                        ),
                                        plotlyOutput("trend_chart", height = "300px")
                                    ),
                                    div(class = "card",
                                        p(class = "card-title", "All Metrics vs D1 Standard"),
                                        plotlyOutput("trend_all_chart", height = "280px")
                                    )
                           ),
                           
                           # ── School Fit ────────────────────────────────────────────────────────
                           tabPanel("School Fit", br(),
                                    div(class = "card",
                                        p(class = "card-title", "School Fit Heatmap"),
                                        p(style = "font-size:11px;color:#aaa;margin:-2px 0 14px",
                                          "Green = meets standard  |  Yellow = within 10%  |  Red = below standard"),
                                        plotlyOutput("heatmap_chart", height = "340px")
                                    ),
                                    div(class = "card",
                                        p(class = "card-title", "Fit Summary"),
                                        tableOutput("fit_table")
                                    )
                           )
               )
        )
      )
  )
)

# ── 8. Server ─────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  ath         <- reactive({ athletes %>% filter(username == input$athlete_sel) })
  ath_history <- reactive({ test_history %>% filter(username == input$athlete_sel) })
  
  # ── Athlete info ──────────────────────────────────────────────────────────────
  output$athlete_info_ui <- renderUI({
    a  <- ath()
    ft <- floor(a$height_in / 12); inch <- a$height_in %% 12
    tagList(
      tags$p(tags$b("Grad Year: "), a$grad_year),
      tags$p(tags$b("Height: "),    paste0(ft, "'", inch, '"')),
      tags$p(tags$b("Weight: "),    paste0(a$weight_lb, " lbs"))
    )
  })
  
  # ── D1 Score cards (sidebar) ──────────────────────────────────────────────────
  output$score_cards_ui <- renderUI({
    d1 <- build_comparison(ath(), "Division 1")
    do.call(tagList, lapply(seq_len(nrow(d1)), function(i) {
      r   <- d1[i, ]
      cls <- paste("score-row", if (isTRUE(r$met)) "met" else "missed")
      div(class = cls,
          div(
            div(class = "score-label", r$short_label),
            div(class = "score-val",   r$score)
          ),
          div(style = "text-align:right",
              div(class = "score-cut", paste0("D1: ", r$cutoff)),
              div(class = "score-cut",
                  if (isTRUE(r$met)) "Met" else paste0(round(abs(r$gap), 2), " to go"))
          )
      )
    }))
  })
  
  # ── Stat mini-cards (overview right column, image 2 style) ───────────────────
  output$stat_cards_ui <- renderUI({
    a  <- ath()
    d1 <- build_comparison(a, "Division 1")
    
    cards <- lapply(seq_len(nrow(d1)), function(i) {
      r      <- d1[i, ]
      pct_v  <- min(r$pct, 100) / 100   # 0–1 for progress bar, capped at 100%
      met    <- isTRUE(r$met)
      fill_c <- if (met) "#1db954" else "#e74c3c"
      status <- if (met) "Met" else paste0(round(abs(r$gap), 2), " ", r$unit, " to go")
      scls   <- if (met) "stat-mini-status met" else "stat-mini-status missed"
      
      div(class = "card", style = "padding:16px;margin-bottom:12px;",
          div(class = "stat-mini",
              div(class = "stat-mini-left",
                  div(class = "stat-mini-label", r$short_label),
                  div(class = "stat-mini-value", r$score),
                  div(class = "stat-mini-unit",  r$unit)
              ),
              div(class = "stat-mini-right",
                  div(class = "stat-mini-cutoff", paste0("D1 standard: ", r$cutoff)),
                  div(class = scls, status)
              )
          ),
          # Thin progress bar at bottom of card
          div(class = "stat-mini-bar",
              div(class = "stat-mini-fill",
                  style = paste0("width:", round(pct_v * 100, 0), "%;background:", fill_c, ";"))
          )
      )
    })
    
    do.call(tagList, cards)
  })
  
  # ── SPIDER CHART — layered concentric zones (image 1 style) ──────────────────
  # Draws filled background rings for D3 / D2 / D1 zones, then plots athlete shape
  output$spider_chart <- renderPlotly({
    c2   <- build_comparison(ath(), input$spider_div) %>% filter(!is.na(pct))
    cats <- c(c2$short_label, c2$short_label[1])   # close the polygon
    
    ath_r <- pmin(c(c2$pct, c2$pct[1]), 130)
    
    # Concentric zone rings — outermost to innermost so fills stack correctly
    # D1 zone = outermost (100%), D2 = 75%, D3 = 50%, below = 25%
    ring_100 <- rep(100, length(cats))
    ring_75  <- rep(75,  length(cats))
    ring_50  <- rep(50,  length(cats))
    ring_25  <- rep(25,  length(cats))
    
    plot_ly(type = "scatterpolar", fill = "toself") %>%
      
      # Zone 4 — outermost, D1 teal (image 1 outer ring)
      add_trace(r = ring_100, theta = cats,
                fillcolor = "rgba(52,211,153,0.35)",
                line = list(color = "rgba(52,211,153,0.6)", width = 1),
                showlegend = FALSE, hoverinfo = "none") %>%
      
      # Zone 3 — D2 yellow-green
      add_trace(r = ring_75, theta = cats,
                fillcolor = "rgba(250,204,21,0.45)",
                line = list(color = "rgba(250,204,21,0.7)", width = 1),
                showlegend = FALSE, hoverinfo = "none") %>%
      
      # Zone 2 — D3 amber/orange
      add_trace(r = ring_50, theta = cats,
                fillcolor = "rgba(251,146,60,0.5)",
                line = list(color = "rgba(251,146,60,0.7)", width = 1),
                showlegend = FALSE, hoverinfo = "none") %>%
      
      # Zone 1 — innermost, red/coral
      add_trace(r = ring_25, theta = cats,
                fillcolor = "rgba(239,68,68,0.55)",
                line = list(color = "rgba(239,68,68,0.7)", width = 1),
                showlegend = FALSE, hoverinfo = "none") %>%
      
      # Athlete shape — dark outline, semi-transparent fill (image 1 black polygon)
      add_trace(r = ath_r, theta = cats,
                name = ath()$display_name,
                fillcolor = "rgba(15,23,42,0.18)",
                line = list(color = "#0f172a", width = 2.5),
                text = paste0(c2$short_label, "<br>", round(c(c2$pct, c2$pct[1]), 1), "%"),
                hoverinfo = "text") %>%
      
      layout(
        polar = list(
          bgcolor = "white",
          radialaxis = list(
            visible   = TRUE,
            range     = c(0, 110),
            tickvals  = c(25, 50, 75, 100),
            ticktext  = c("25 PCTL", "50 PCTL", "75 PCTL", "100 PCTL"),
            tickfont  = list(size = 9, color = "#999"),
            gridcolor = "rgba(0,0,0,0.06)",
            linecolor = "rgba(0,0,0,0.08)",
            tickangle = 0
          ),
          angularaxis = list(
            tickfont  = list(size = 12, color = "#222", family = "Segoe UI"),
            linecolor = "rgba(0,0,0,0.1)",
            gridcolor = "rgba(0,0,0,0.06)"
          )
        ),
        showlegend = FALSE,
        margin     = list(t = 40, b = 40, l = 60, r = 60),
        paper_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── OPTION A: Scorecard tiles ─────────────────────────────────────────────────
  output$scorecard_tiles_ui <- renderUI({
    d1 <- build_comparison(ath(), "Division 1")
    tiles <- lapply(seq_len(nrow(d1)), function(i) {
      r     <- d1[i, ]
      met   <- isTRUE(r$met)
      cls   <- paste("tile", if (met) "met" else "missed")
      level <- {
        score <- r$score; lb <- r$lower_better
        d2c <- get_cutoff(bm, r$field_name, "Division 2")
        d3c <- get_cutoff(bm, r$field_name, "Division 3")
        if (lb) {
          if (score <= r$cutoff) "D1 Level" else
            if (score <= d2c)      "D2 Level" else
              if (score <= d3c)      "D3 Level" else "Below D3"
        } else {
          if (score >= r$cutoff) "D1 Level" else
            if (score >= d2c)      "D2 Level" else
              if (score >= d3c)      "D3 Level" else "Below D3"
        }
      }
      gap_txt <- if (met) paste0("+", round(abs(r$gap), 2), " above D1")
      else     paste0(round(abs(r$gap), 2), " ", r$unit, " from D1")
      
      div(class = cls,
          div(class = "tile-metric", r$short_label),
          div(class = "tile-score",  r$score),
          div(class = "tile-unit",   r$unit),
          div(class = "tile-div",    level),
          div(class = "tile-gap",    gap_txt)
      )
    })
    div(class = "tile-grid", do.call(tagList, tiles))
  })
  
  # ── OPTION B: Progress rings ──────────────────────────────────────────────────
  make_ring <- function(idx) {
    renderPlotly({
      tm    <- test_map[idx, ]
      score <- get_score(ath(), tm$field_name)
      d1c   <- get_cutoff(bm, tm$field_name, "Division 1")
      pct_v <- min(round(pct_of_benchmark(score, d1c, tm$lower_better), 1), 130)
      fill  <- if (pct_v >= 100) "#1db954" else if (pct_v >= 75) "#f9ab00" else "#e74c3c"
      remain <- max(0, 100 - pct_v)
      
      plot_ly(
        values = c(min(pct_v, 100), remain),
        labels = c("Achieved", "Remaining"),
        type   = "pie", hole = 0.72,
        marker = list(colors = c(fill, "#f0f0f0"),
                      line   = list(color = "white", width = 2)),
        textinfo  = "none",
        hoverinfo = "none",
        showlegend = FALSE
      ) %>%
        layout(
          annotations = list(
            list(text = paste0("<b>", pct_v, "%</b>"),
                 x = 0.5, y = 0.55, showarrow = FALSE,
                 font = list(size = 16, color = "#111")),
            list(text = tm$short_label,
                 x = 0.5, y = 0.35, showarrow = FALSE,
                 font = list(size = 10, color = "#888"))
          ),
          margin        = list(t = 10, b = 10, l = 10, r = 10),
          paper_bgcolor = "rgba(0,0,0,0)"
        ) %>%
        config(displayModeBar = FALSE)
    })
  }
  
  output$ring_1 <- make_ring(1)
  output$ring_2 <- make_ring(2)
  output$ring_3 <- make_ring(3)
  output$ring_4 <- make_ring(4)
  
  # ── OPTION C: Bullet charts ───────────────────────────────────────────────────
  output$bullet_chart <- renderPlotly({
    a   <- ath()
    fig <- plot_ly()
    
    for (i in seq_len(nrow(test_map))) {
      tm    <- test_map[i, ]
      score <- get_score(a, tm$field_name)
      d1c   <- get_cutoff(bm, tm$field_name, "Division 1")
      d2c   <- get_cutoff(bm, tm$field_name, "Division 2")
      d3c   <- get_cutoff(bm, tm$field_name, "Division 3")
      lo    <- tm$gauge_min
      hi    <- tm$gauge_max
      met   <- isTRUE(meets_benchmark(score, d1c, tm$lower_better))
      dot_c <- if (met) "#1db954" else "#e74c3c"
      
      # For lower-is-better, flip so right = better on all bars
      flip  <- tm$lower_better
      norm  <- function(v) if (flip) (hi - v) / (hi - lo) * 100
      else      (v  - lo) / (hi - lo) * 100
      
      n_score <- norm(score)
      n_d3    <- norm(d3c)
      n_d2    <- norm(d2c)
      n_d1    <- norm(d1c)
      ylab    <- tm$short_label
      
      # Background range bars (stacked, left to right: below D3, D3, D2, D1)
      mins <- sort(c(0, n_d3, n_d2, n_d1))
      cols <- c("#fee2e2","#dcfce7","#fef9c3","#dbeafe")
      
      for (j in seq_len(4)) {
        seg_w <- if (j < 4) mins[j+1] - mins[j] else 100 - mins[j]
        fig <- add_trace(fig,
                         type = "bar", orientation = "h",
                         x = seg_w, y = ylab, base = mins[j],
                         marker = list(color = cols[j], line = list(width = 0)),
                         showlegend = FALSE, hoverinfo = "none"
        )
      }
      
      # Athlete score dot
      fig <- add_trace(fig,
                       type = "scatter", mode = "markers",
                       x = n_score, y = ylab,
                       marker = list(symbol = "line-ns", size = 18,
                                     color = dot_c, line = list(color = dot_c, width = 4)),
                       text = paste0(tm$short_label, ": ", score, " ", tm$unit),
                       hoverinfo = "text", showlegend = FALSE
      )
      
      # D1 cutoff marker line
      fig <- add_trace(fig,
                       type = "scatter", mode = "markers",
                       x = n_d1, y = ylab,
                       marker = list(symbol = "line-ns", size = 18,
                                     color = "#333", line = list(color = "#333", width = 2)),
                       text = paste0("D1 cutoff: ", d1c, " ", tm$unit),
                       hoverinfo = "text", showlegend = FALSE
      )
    }
    
    fig %>% layout(
      barmode = "stack",
      xaxis   = list(title = "← Worse    Better →",
                     range = c(0, 100), showticklabels = FALSE,
                     zeroline = FALSE, showgrid = FALSE),
      yaxis   = list(title = "", tickfont = list(size = 12),
                     showgrid = FALSE),
      annotations = list(
        list(x = 0.01, y = 1.06, xref = "paper", yref = "paper",
             showarrow = FALSE, text = "Below D3",
             font = list(size = 10, color = "#e74c3c")),
        list(x = 0.35, y = 1.06, xref = "paper", yref = "paper",
             showarrow = FALSE, text = "D3 zone",
             font = list(size = 10, color = "#888")),
        list(x = 0.62, y = 1.06, xref = "paper", yref = "paper",
             showarrow = FALSE, text = "D2 zone",
             font = list(size = 10, color = "#888")),
        list(x = 0.88, y = 1.06, xref = "paper", yref = "paper",
             showarrow = FALSE, text = "D1 zone",
             font = list(size = 10, color = "#1db954"))
      ),
      margin        = list(l = 10, r = 20, t = 30, b = 30),
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor  = "rgba(0,0,0,0)"
    ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── Percentile spectrum ────────────────────────────────────────────────────────
  output$percentile_ui <- renderUI({
    a <- ath()
    
    legend_row <- div(
      style = "display:flex;gap:16px;flex-wrap:wrap;margin-bottom:14px;font-size:11px;color:#888",
      div(style="display:flex;align-items:center;gap:5px",
          div(style="width:12px;height:12px;border-radius:2px;background:#fee2e2"), "Below D3"),
      div(style="display:flex;align-items:center;gap:5px",
          div(style="width:12px;height:12px;border-radius:2px;background:#dcfce7"), "D3"),
      div(style="display:flex;align-items:center;gap:5px",
          div(style="width:12px;height:12px;border-radius:2px;background:#fef9c3"), "D2"),
      div(style="display:flex;align-items:center;gap:5px",
          div(style="width:12px;height:12px;border-radius:2px;background:#dbeafe"), "D1")
    )
    
    rows <- lapply(seq_len(nrow(test_map)), function(i) {
      tm    <- test_map[i, ]
      d1c   <- get_cutoff(bm, tm$field_name, "Division 1")
      d2c   <- get_cutoff(bm, tm$field_name, "Division 2")
      d3c   <- get_cutoff(bm, tm$field_name, "Division 3")
      score <- get_score(a, tm$field_name)
      lo    <- tm$gauge_min; hi <- tm$gauge_max
      
      to_pct <- function(v) round((v - lo) / (hi - lo) * 100, 1)
      
      if (tm$lower_better) {
        p_score <- 100 - to_pct(score)
        p_d3    <- 100 - to_pct(d3c)
        p_d2    <- 100 - to_pct(d2c)
        p_d1    <- 100 - to_pct(d1c)
      } else {
        p_score <- to_pct(score); p_d3 <- to_pct(d3c)
        p_d2    <- to_pct(d2c);   p_d1  <- to_pct(d1c)
      }
      
      dot_pos  <- max(3, min(97, p_score))
      w_red    <- min(p_d3, 100)
      w_green  <- max(0, min(p_d2, 100) - w_red)
      w_yellow <- max(0, min(p_d1, 100) - w_red - w_green)
      w_blue   <- max(0, 100 - w_red - w_green - w_yellow)
      
      level <- if (p_score >= p_d1) "D1" else if (p_score >= p_d2) "D2" else
        if (p_score >= p_d3) "D3" else "Below D3"
      
      div(class = "pct-row",
          div(style = "display:flex;align-items:center;justify-content:space-between;margin-bottom:6px",
              div(class = "pct-metric-name", tm$short_label),
              div(style = "font-size:11px;font-weight:700;color:#555;", level)
          ),
          div(style = "position:relative;height:20px;border-radius:10px;overflow:visible;",
              div(style = "display:flex;height:20px;border-radius:10px;overflow:hidden;",
                  div(style = paste0("width:", w_red,    "%;background:#fee2e2;")),
                  div(style = paste0("width:", w_green,  "%;background:#dcfce7;")),
                  div(style = paste0("width:", w_yellow, "%;background:#fef9c3;")),
                  div(style = paste0("width:", w_blue,   "%;background:#dbeafe;"))
              ),
              div(style = paste0(
                "position:absolute;top:50%;left:", dot_pos, "%;",
                "transform:translate(-50%,-50%);",
                "width:18px;height:18px;border-radius:50%;",
                "background:#0d1b2a;border:3px solid white;",
                "box-shadow:0 1px 4px rgba(0,0,0,0.3);"
              ))
          ),
          div(class = "pct-score-line",
              paste0(score, " ", tm$unit,
                     "  —  D3: ", d3c, "  D2: ", d2c, "  D1: ", d1c))
      )
    })
    
    do.call(tagList, c(list(legend_row), rows))
  })
  
  # ── Bar chart ──────────────────────────────────────────────────────────────────
  output$bar_chart <- renderPlotly({
    c2  <- build_comparison(ath(), input$bar_div) %>% filter(!is.na(cutoff))
    clr <- ifelse(c2$met, "rgba(29,185,84,0.8)", "rgba(231,76,60,0.8)")
    bdr <- ifelse(c2$met, "#1db954", "#e74c3c")
    plot_ly() %>%
      add_trace(x = c2$cutoff, y = c2$short_label,
                type = "bar", orientation = "h",
                name = paste(input$bar_div, "Cutoff"),
                marker = list(color = "rgba(200,200,200,0.5)",
                              line  = list(color = "#ccc", width = 1))) %>%
      add_trace(x = c2$score, y = c2$short_label,
                type = "bar", orientation = "h",
                name = ath()$display_name,
                marker = list(color = clr, line = list(color = bdr, width = 1.5))) %>%
      layout(
        barmode = "overlay",
        xaxis   = list(title = "Score", zeroline = FALSE),
        yaxis   = list(title = "", tickfont = list(size = 12)),
        legend  = list(orientation = "h", y = -0.22),
        margin  = list(l = 10, r = 20, t = 10, b = 60),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── Gap chart ──────────────────────────────────────────────────────────────────
  output$gap_chart <- renderPlotly({
    c2 <- build_comparison(ath(), input$gap_div) %>%
      filter(!is.na(cutoff)) %>%
      mutate(
        gap_display = ifelse(isTRUE(met), -abs(gap), abs(gap)),
        bar_color   = ifelse(isTRUE(met), "#1db954", "#e74c3c"),
        label_txt   = ifelse(isTRUE(met),
                             paste0("+", round(abs(gap), 2), " above"),
                             paste0(round(abs(gap), 2), " to go"))
      )
    plot_ly(c2,
            x = ~gap_display, y = ~reorder(short_label, gap_display),
            type = "bar", orientation = "h",
            text = ~label_txt, textposition = "outside", hoverinfo = "text",
            marker = list(color = ~bar_color, line = list(color = ~bar_color, width = 1))
    ) %>%
      layout(
        xaxis  = list(title = "Gap to cutoff",
                      zeroline = TRUE, zerolinecolor = "#ccc", zerolinewidth = 1.5),
        yaxis  = list(title = "", tickfont = list(size = 12)),
        margin = list(l = 10, r = 130, t = 10, b = 50),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── Trend chart ────────────────────────────────────────────────────────────────
  output$trend_chart <- renderPlotly({
    hist  <- ath_history()
    tm    <- test_map %>% filter(field_name == input$trend_metric)
    div_c <- get_cutoff(bm, input$trend_metric, input$trend_div)
    plot_ly(hist, x = ~test_date, y = ~get(input$trend_metric),
            type = "scatter", mode = "lines+markers",
            name = ath()$display_name,
            line   = list(color = "#e74c3c", width = 2.5),
            marker = list(color = "#e74c3c", size = 8,
                          line = list(color = "white", width = 2)),
            fill = "tozeroy", fillcolor = "rgba(231,76,60,0.08)") %>%
      add_trace(x = range(hist$test_date), y = rep(div_c, 2),
                type = "scatter", mode = "lines",
                name = paste(input$trend_div, "Standard"),
                line = list(color = "#f9ab00", dash = "dash", width = 1.5)) %>%
      layout(
        xaxis  = list(title = "Test Date", showgrid = FALSE),
        yaxis  = list(title = tm$label, showgrid = TRUE,
                      gridcolor = "rgba(0,0,0,0.05)"),
        legend = list(orientation = "h", y = -0.22),
        margin = list(l = 50, r = 20, t = 20, b = 65),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  output$trend_all_chart <- renderPlotly({
    hist   <- ath_history()
    d1_bm  <- bm %>% filter(division == "Division 1")
    colors <- c("#e74c3c","#1db954","#f9ab00","#3b82f6")
    fig    <- plot_ly()
    for (i in seq_len(nrow(test_map))) {
      tm    <- test_map[i, ]
      cut_v <- d1_bm %>% filter(field_name == tm$field_name) %>% pull(cutoff)
      pcts  <- sapply(hist[[tm$field_name]],
                      function(s) pct_of_benchmark(s, cut_v, tm$lower_better))
      fig   <- add_trace(fig, x = hist$test_date, y = pcts,
                         type = "scatter", mode = "lines+markers",
                         name = tm$short_label,
                         line   = list(color = colors[i], width = 2),
                         marker = list(color = colors[i], size = 7))
    }
    fig %>%
      add_trace(x = range(hist$test_date), y = rep(100, 2),
                type = "scatter", mode = "lines", name = "D1 Standard",
                line = list(color = "#aaa", dash = "dot", width = 1.5)) %>%
      layout(
        xaxis  = list(title = "Test Date", showgrid = FALSE),
        yaxis  = list(title = "% of D1 Standard", ticksuffix = "%",
                      gridcolor = "rgba(0,0,0,0.05)"),
        legend = list(orientation = "h", y = -0.25),
        margin = list(l = 55, r = 20, t = 10, b = 75),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── School fit heatmap ─────────────────────────────────────────────────────────
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
      for (mi in seq_len(nrow(test_map))) {
        pv <- mat[si, mi]
        hover[si, mi] <- paste0(schools$school[si], " (", schools$division[si], ")\n",
                                test_map$short_label[mi], ": ", round(pv, 0), "% of standard")
      }
    plot_ly(z = pmin(pmax(mat, 0), 130),
            x = test_map$short_label,
            y = paste0(schools$school, " (", schools$division, ")"),
            type = "heatmap", text = hover, hoverinfo = "text",
            colorscale = list(list(0, "#ef4444"), list(0.69, "#fde68a"),
                              list(0.77, "#34a853"), list(1, "#166534")),
            zmin = 0, zmax = 130, showscale = TRUE,
            colorbar = list(title = "% of Cutoff",
                            tickvals = c(0, 90, 100, 115, 130),
                            ticktext = c("0%","90%","Cutoff","115%","130%+"),
                            tickfont = list(size = 10))) %>%
      layout(
        xaxis  = list(title = "", tickfont = list(size = 12)),
        yaxis  = list(title = "", tickfont = list(size = 11)),
        margin = list(l = 180, r = 90, t = 10, b = 60),
        paper_bgcolor = "rgba(0,0,0,0)"
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── School fit table ───────────────────────────────────────────────────────────
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
        School         = sc$school,
        Division       = sc$division,
        Benchmarks_Met = paste0(n_met, " / ", nrow(test_map)),
        Fit_Status     = if (n_met == nrow(test_map)) "Strong Fit"
        else if (n_met >= 2) "Partial Fit"
        else "Needs Work",
        stringsAsFactors = FALSE
      )
    }))
  }, striped = TRUE, hover = TRUE, bordered = TRUE, spacing = "s", width = "100%")
}

shinyApp(ui = ui, server = server)