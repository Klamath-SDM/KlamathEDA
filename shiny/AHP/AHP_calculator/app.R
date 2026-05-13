library(shiny)
library(DT)
library(openxlsx)
library(ggplot2)
library(shinyjs)

# ── AHP Scale ──────────────────────────────────────────────────────────────────
AHP_VALUES <- 1:9
AHP_LABELS <- c("Equal","Weak","Moderate","Mod+","Strong","Strong+","Very Strong","Very+","Absolute")
RI <- c(0, 0, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45, 1.49)

# ── Tab definitions ────────────────────────────────────────────────────────────
TABS <- list(
  
  vehicle = list(
    id       = "vehicle",
    label    = "Vehicle Purchase",
    group    = "Example",
    desc     = "A classic AHP walkthrough. You want to purchase a vehicle and have identified three attributes: Hauling Capacity, Fuel Efficiency, and Safety. The matrix is pre-filled with the example judgments from the original illustration — Fuel Efficiency is moderately more important than Hauling Capacity (3), Safety is strongly more important than Hauling Capacity (5), and Safety is between strongly and very strongly more important than Fuel Efficiency (6). Try changing values to see how the weights shift, or hit Reset to restore the original example.",
    criteria = c("Hauling capacity", "Fuel efficiency", "Safety"),
    preset   = matrix(c(1, 1/3, 1/5,
                        3,   1, 1/6,
                        5,   6,   1), nrow = 3, byrow = TRUE)
  ),
  
  spring_chin = list(
    id       = "spring_chin",
    label    = "Spring-run Chinook",
    group    = "Salmon",
    desc     = "AHP weighting for Spring-run Chinook salmon monitoring attributes. These biological indicators measure population viability. Compare each pair to reflect which attribute provides more critical information for assessing population health.",
    criteria = c(
      "Number natural adult spawners",
      "Smolt abundance",
      "Nat. origin juvenile per adult spawner",
      "Nat. produced adult/spawner",
      "Coho/Spring Chinook: spawning and juvenile distribution",
      "Smolt outmigration timing: mean and range (tails)",
      "Adult return timing: mean and range (tails)",
      "Size of outmigrating smolts: mean and range",
      "Prop females with >50% eggs",
      "% juveniles C. shasta",
      "% returning adults with Ich"
    )
  ),

  fall_chin = list(
    id       = "fall_chin",
    label    = "Fall-run Chinook",
    group    = "Salmon",
    desc     = "AHP weighting for Fall-run Chinook salmon monitoring attributes. Compare each pair to reflect which indicator is more important for tracking this population's status and trends.",
    criteria = c(
      "Number natural adult spawners",
      "Smolt abundance",
      "Nat. origin juvenile per adult spawner",
      "Nat. produced adult/spawner",
      "Fall Chinook: spawning distribution (IP models of historic)",
      "Smolt outmigration timing: mean and range (tails)",
      "Adult return timing: mean and range (tails)",
      "Size of outmigrating smolts: mean and range",
      "Prop females with >50% eggs",
      "% juveniles C. shasta",
      "% returning adults with Ich"
    )
  ),

  coho = list(
    id       = "coho",
    label    = "Coho Salmon",
    group    = "Salmon",
    desc     = "AHP weighting for Coho salmon monitoring attributes. Compare each pair of biological indicators to reflect their relative importance for assessing population health and recovery.",
    criteria = c(
      "Number natural adult spawners",
      "Smolt abundance",
      "Nat. origin juvenile per adult spawner",
      "Nat. produced adult/spawner",
      "Coho/Spring Chinook: spawning and juvenile distribution",
      "Smolt outmigration timing: mean and range (tails)",
      "Adult return timing: mean and range (tails)",
      "Size of outmigrating smolts: mean and range",
      "Prop females with >50% eggs",
      "% juveniles C. shasta",
      "% returning adults with Ich"
    )
  ),

  lost_riv_sucker = list(
    id       = "lost_riv_sucker",
    label    = "Lost River Sucker",
    group    = "Suckers",
    desc     = "AHP weighting for Lost River Sucker monitoring attributes. These indicators track population abundance, reproductive success, and hatchery program performance. Compare each pair to reflect relative importance for assessing species recovery.",
    criteria = c(
      "Abundance",
      "% Historical spawning sites occupied (LRS only)",
      "Multiple cohorts in spawning populations (age structure diversity)",
      "Juvenile production (age 0+ abundance)",
      "Recruitment to adults (number adult recruits)",
      "Number of broodstock on hand (by species, genetic lineage, crosses)",
      "Adult gamete harvest success rates",
      "Number of fish available for stocking (by age, species, genetic lineage)",
      "Release survival and contribution to wild populations"
    )
  ),
  
  shortnose_sucker = list(
    id       = "shortnose_sucker",
    label    = "Shortnose Sucker",
    group    = "Suckers",
    desc     = "AHP weighting for Shortnose Sucker monitoring attributes. Compare each pair of population and hatchery indicators to reflect their relative importance for assessing this species' recovery trajectory.",
    criteria = c(
      "Abundance",
      "Multiple cohorts in spawning populations (age structure diversity)",
      "Juvenile production (age 0+ abundance)",
      "Recruitment to adults (number adult recruits)",
      "Number of broodstock on hand (by species, genetic lineage, crosses)",
      "Adult gamete harvest success rates",
      "Number of fish available for stocking (by age, species, genetic lineage)",
      "Release survival and contribution to wild populations"
    )
  ),
  
  klamath_sucker = list(
    id       = "klamath_sucker",
    label    = "Klamath Largescale Sucker",
    group    = "Suckers",
    desc     = "AHP weighting for Klamath Largescale Sucker monitoring attributes. Compare each pair of indicators to reflect their relative importance for assessing the population's status and management needs.",
    criteria = c(
      "Abundance",
      "Multiple cohorts in spawning populations (age structure diversity)",
      "Juvenile production (age 0+ abundance)",
      "Recruitment to adults (number adult recruits)",
      "Number of broodstock on hand (by species, genetic lineage, crosses)",
      "Adult gamete harvest success rates",
      "Number of fish available for stocking (by age, species, genetic lineage)",
      "Release survival and contribution to wild populations"
    )
  ),
  
  water_ag = list(
    id       = "water_ag",
    label    = "Water for Agriculture",
    group    = "Water",
    desc     = "AHP weighting for agricultural water supply indicators in the Klamath Basin. Compare each pair of metrics to reflect their relative importance for assessing water availability and sustainability for agricultural users.",
    criteria = c(
      "Percentage of full water allocation received each year",
      "Number of consecutive years with at least 80% water allocation",
      "Number of acres in production vs. fallowed",
      "Groundwater depletion rates vs. recharge rates (differ region)",
      "Acre feet returned (after use) to the basin, annual & seasonal measure"
    )
  )
)

# ── AHP computation ────────────────────────────────────────────────────────────
compute_ahp <- function(mat) {
  n <- nrow(mat)
  col_sums  <- colSums(mat)
  norm_mat  <- sweep(mat, 2, col_sums, "/")
  weights   <- rowMeans(norm_mat)
  lambda_max <- mean(as.numeric(mat %*% weights) / weights)
  CI <- (lambda_max - n) / (n - 1)
  ri <- if (n <= length(RI)) RI[n] else 1.49
  CR <- if (ri == 0) 0 else CI / ri
  list(weights = weights, lambda_max = lambda_max, CI = CI, CR = CR)
}

init_matrix   <- function(n) matrix(1, n, n)
pair_input_id <- function(tab_id, i, j) paste0(tab_id, "_pair_", i, "_", j)

# ── UI ─────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$title("AHP Klamath Basin Weighting Tool"),
    tags$style(HTML("
      body { font-family: 'Segoe UI', Arial, sans-serif; background: #f4f7f9; color: #2c3e50; margin: 0; }
      .app-header { background: #1a3a4a; padding: 14px 28px; border-bottom: 3px solid #2e86ab; }
      .app-header h2 { color: #fff; margin: 0; font-size: 21px; font-weight: 600; }
      .app-header .subtitle { color: #a8ccd8; font-size: 13px; margin-top: 3px; }
      .group-bar { background: #22506a; padding: 0 28px; border-bottom: 2px solid #1a3a4a; }
      .group-bar .nav-tabs { border: none; }
      .group-bar .nav-tabs > li > a { color: #a8ccd8; border: none; border-radius: 0; padding: 11px 22px; font-size: 13px; font-weight: 600; }
      .group-bar .nav-tabs > li.active > a,
      .group-bar .nav-tabs > li > a:hover { color: #fff; background: transparent; border-bottom: 3px solid #f0a500; }
      .sub-bar { background: #2d6a8a; padding: 0 28px; border-bottom: 1px solid #1f4f68; min-height: 40px; }
      .sub-bar .nav-tabs { border: none; }
      .sub-bar .nav-tabs > li > a { color: #c8dfe8; border: none; border-radius: 0; padding: 9px 18px; font-size: 12px; font-weight: 500; }
      .sub-bar .nav-tabs > li.active > a,
      .sub-bar .nav-tabs > li > a:hover { color: #fff; background: transparent; border-bottom: 2px solid #2e86ab; }
      .main-panel { padding: 22px 28px; max-width: 1400px; margin: 0 auto; }
      .info-box { background: #e8f4f8; border-left: 4px solid #2e86ab; border-radius: 6px; padding: 13px 17px; margin-bottom: 18px; font-size: 14px; line-height: 1.6; }
      .scale-box { background: #fff; border: 1px solid #d0dde5; border-radius: 8px; padding: 16px 20px; margin-bottom: 18px; }
      .scale-box h4 { margin: 0 0 6px; color: #1a3a4a; font-size: 14px; }
      .scale-grid-desc { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 8px; margin-top: 10px; }
      .scale-desc-item { display: flex; align-items: flex-start; gap: 12px; background: #f4f7f9; border-radius: 6px; padding: 10px 12px; }
      .scale-inverse-item { background: #eef4f8; border: 1px dashed #b0c4ce; }
      .scale-num-lg { font-size: 22px; font-weight: 800; color: #2e86ab; min-width: 32px; text-align: center; line-height: 1.2; padding-top: 2px; }
      .scale-inv-num { color: #5a9ab8; font-size: 18px; }
      .scale-desc-text { font-size: 12px; line-height: 1.5; color: #444; }
      .scale-desc-text b { color: #1a3a4a; font-size: 12.5px; }
      .section-card { background: #fff; border: 1px solid #d0dde5; border-radius: 8px; padding: 18px 20px; margin-bottom: 18px; box-shadow: 0 1px 4px rgba(0,0,0,.05); }
      .section-card h3 { margin: 0 0 14px; color: #1a3a4a; font-size: 15px; border-bottom: 1px solid #e8eef2; padding-bottom: 9px; }
      .pairwise-table { width: 100%; border-collapse: collapse; }
      .pairwise-table th { background: #1a3a4a; color: #fff; font-size: 11px; padding: 7px 8px; text-align: center; }
      .pairwise-table td { vertical-align: middle; font-size: 12px; padding: 4px 6px; border: 1px solid #e0e8ed; }
      .row-label { font-weight: 600; color: #1a3a4a; background: #e8f4f8; font-size: 11px; max-width: 200px; }
      .diag-cell { background: #d8e6ed; color: #888; text-align: center; }
      .inv-cell  { text-align: center; color: #777; background: #f7fafb; }
      .select-cell select { font-size: 11px; padding: 2px 4px; border: 1px solid #b0c4ce; border-radius: 4px; width: 100%; min-width: 85px; }
      .weight-bar-wrap { display: flex; align-items: center; gap: 7px; }
      .weight-bar { height: 16px; background: #2e86ab; border-radius: 3px; min-width: 4px; }
      .cr-badge { display: inline-block; padding: 5px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; }
      .cr-ok   { background: #d4edda; color: #155724; }
      .cr-warn { background: #fff3cd; color: #856404; }
      .cr-bad  { background: #f8d7da; color: #721c24; }
      .btn-reset { background: #6c757d; color: #fff; border: none; border-radius: 5px; padding: 8px 16px; font-size: 13px; cursor: pointer; margin-right: 8px; }
      .btn-reset:hover { background: #5a6268; }
      .btn-dl { background: #2e86ab; color: #fff; border: none; border-radius: 5px; padding: 8px 16px; font-size: 13px; cursor: pointer; }
      .btn-dl:hover { background: #1a6a8a; }
      .results-grid { display: grid; grid-template-columns: 1.4fr 1fr; gap: 18px; }
      .stat-row td { padding: 5px 8px; font-size: 13px; }
      .stat-row:nth-child(even) { background: #f4f7f9; }
      @media(max-width: 900px) { .results-grid { grid-template-columns: 1fr; } }
    "))
  ),
  
  div(class = "app-header",
      h2("\U0001F41F Klamath Basin AHP Weighting Tool"),
      div(class = "subtitle", "Analytic Hierarchy Process — Pairwise Comparison & Weight Calculation")
  ),
  
  div(class = "group-bar",
      tabsetPanel(id = "group_tabs", type = "tabs",
                  tabPanel("\U0001F4D6 Example",               value = "Example"),
                  tabPanel("\U0001F41F Salmon",                value = "Salmon"),
                  tabPanel("\U0001F420 Suckers",               value = "Suckers"),
                  tabPanel("\U0001F4A7 Water for Agriculture", value = "Water")
      )
  ),
  
  div(class = "sub-bar", uiOutput("sub_tabs_ui")),
  div(class = "main-panel", uiOutput("tab_content"))
)

# ── Server ─────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  mat_store <- reactiveValues(
    vehicle          = NULL,
    spring_chin      = NULL,
    fall_chin        = NULL,
    coho             = NULL,
    lost_riv_sucker  = NULL,
    shortnose_sucker = NULL,
    klamath_sucker   = NULL,
    water_ag         = NULL
  )
  
  get_mat <- function(tid) {
    m <- mat_store[[tid]]
    if (is.null(m)) {
      preset <- TABS[[tid]]$preset
      m <- if (!is.null(preset)) preset else init_matrix(length(TABS[[tid]]$criteria))
    }
    m
  }
  set_mat <- function(tid, mat) mat_store[[tid]] <- mat
  
  group_tab_ids <- function(grp) names(Filter(function(t) t$group == grp, TABS))
  
  current_tab <- reactive({
    grp <- input$group_tabs %||% "Salmon"
    ids <- group_tab_ids(grp)
    sel <- input$sub_tabs
    if (!is.null(sel) && sel %in% ids) sel else ids[1]
  })
  
  output$sub_tabs_ui <- renderUI({
    grp <- input$group_tabs %||% "Salmon"
    ids <- group_tab_ids(grp)
    if (length(ids) <= 1) return(NULL)
    do.call(tabsetPanel, c(list(id = "sub_tabs", type = "tabs"),
                           lapply(ids, function(id) tabPanel(TABS[[id]]$label, value = id))
    ))
  })
  
  # Register observers for all tabs upfront
  lapply(names(TABS), function(tid) {
    crit <- TABS[[tid]]$criteria
    n    <- length(crit)
    for (i in seq_len(n)) for (j in seq_len(n)) if (j > i) {
      local({
        li <- i; lj <- j
        iid <- pair_input_id(tid, li, lj)
        observeEvent(input[[iid]], {
          m <- get_mat(tid)
          v <- as.numeric(input[[iid]])
          m[li, lj] <- v; m[lj, li] <- 1/v
          set_mat(tid, m)
        }, ignoreInit = TRUE)
      })
    }
  })
  
  observeEvent(input$btn_reset, {
    tid    <- current_tab()
    preset <- TABS[[tid]]$preset
    m      <- if (!is.null(preset)) preset else init_matrix(length(TABS[[tid]]$criteria))
    set_mat(tid, m)
    n <- length(TABS[[tid]]$criteria)
    for (i in seq_len(n)) for (j in seq_len(n)) if (j > i) {
      val <- round(m[i, j], 6)
      updateSelectInput(session, pair_input_id(tid, i, j), selected = as.character(val))
    }
  })
  
  output$btn_download <- downloadHandler(
    filename = function() paste0("AHP_", current_tab(), "_", Sys.Date(), ".xlsx"),
    content  = function(file) {
      tid  <- current_tab()
      tab  <- TABS[[tid]]
      crit <- tab$criteria
      m    <- get_mat(tid)
      ahp  <- compute_ahp(m)
      n    <- length(crit)
      wb   <- createWorkbook()
      hs   <- createStyle(fgFill="#1a3a4a", fontColour="#FFFFFF", fontName="Arial",
                          fontSize=11, textDecoration="bold", halign="center", wrapText=TRUE)
      rs   <- createStyle(fgFill="#e8f4f8", fontName="Arial", fontSize=10,
                          textDecoration="bold", wrapText=TRUE)
      ds   <- createStyle(fgFill="#d0dde5", fontName="Arial", fontSize=10, halign="center")
      ns   <- createStyle(fontName="Arial", fontSize=10, halign="center", numFmt="0.000")
      
      addWorksheet(wb, "Pairwise Matrix")
      writeData(wb, "Pairwise Matrix", "", startRow=1, startCol=1)
      for (j in seq_len(n)) writeData(wb, "Pairwise Matrix", crit[j], startRow=1, startCol=j+1)
      addStyle(wb, "Pairwise Matrix", hs, rows=1, cols=1:(n+1), gridExpand=TRUE)
      for (i in seq_len(n)) {
        writeData(wb, "Pairwise Matrix", crit[i], startRow=i+1, startCol=1)
        addStyle(wb, "Pairwise Matrix", rs, rows=i+1, cols=1)
        for (j in seq_len(n)) {
          writeData(wb, "Pairwise Matrix", round(m[i,j],4), startRow=i+1, startCol=j+1)
          addStyle(wb, "Pairwise Matrix", if(i==j) ds else ns, rows=i+1, cols=j+1)
        }
      }
      setColWidths(wb, "Pairwise Matrix", cols=1:(n+1), widths=c(42, rep(11,n)))
      
      addWorksheet(wb, "Weights")
      wdf <- data.frame(Criterion=crit, Weight=round(ahp$weights,4),
                        `Weight %`=paste0(round(ahp$weights*100,1),"%"),
                        Rank=rank(-ahp$weights), check.names=FALSE)
      wdf <- wdf[order(wdf$Rank),]
      writeData(wb, "Weights", wdf, startRow=1)
      addStyle(wb, "Weights", hs, rows=1, cols=1:4, gridExpand=TRUE)
      setColWidths(wb, "Weights", cols=1:4, widths=c(50,12,12,8))
      cdf <- data.frame(Metric=c("Lambda Max","CI","CR","Interpretation"),
                        Value=c(round(ahp$lambda_max,4), round(ahp$CI,4), round(ahp$CR,4),
                                if(ahp$CR<0.1) "ACCEPTABLE" else if(ahp$CR<0.2) "MARGINAL" else "INCONSISTENT"))
      writeData(wb, "Weights", cdf, startRow=n+4)
      addStyle(wb, "Weights", hs, rows=n+4, cols=1:2, gridExpand=TRUE)
      setColWidths(wb, "Weights", cols=1:2, widths=c(40,30))
      
      saveWorkbook(wb, file, overwrite=TRUE)
    }
  )
  
  output$tab_content <- renderUI({
    tid  <- current_tab()
    tab  <- TABS[[tid]]
    crit <- tab$criteria
    n    <- length(crit)
    m    <- get_mat(tid)
    ahp  <- compute_ahp(m)
    
    header_cells <- c(list(tags$th("")), lapply(crit, tags$th))
    
    pair_rows <- lapply(seq_len(n), function(i) {
      cells <- lapply(seq_len(n), function(j) {
        if (i == j) {
          tags$td(class="diag-cell", "\u2014")
        } else if (j < i) {
          val <- m[i,j]
          lbl <- if (val < 1) paste0("1/", round(1/val)) else as.character(round(val))
          tags$td(class="inv-cell", lbl)
        } else {
          iid <- pair_input_id(tid, i, j)
          cur <- m[i,j]
          tags$td(class="select-cell",
                  tags$select(id=iid,
                              onchange=sprintf("Shiny.setInputValue('%s',this.value,{priority:'event'})", iid),
                              lapply(AHP_VALUES, function(v) {
                                tags$option(value=v, selected=if(abs(cur-v)<0.01) "" else NULL,
                                            paste0(v," \u2013 ",AHP_LABELS[v]))
                              }),
                              lapply(2:9, function(v) {
                                frac <- round(1/v, 6)
                                tags$option(value=frac, selected=if(abs(cur-frac)<0.005) "" else NULL,
                                            paste0("1/",v," \u2013 ",AHP_LABELS[v]," (inv)"))
                              })
                  )
          )
        }
      })
      tags$tr(tags$td(class="row-label", crit[i]), cells)
    })
    
    ord <- order(ahp$weights, decreasing=TRUE)
    weight_rows <- lapply(ord, function(i) {
      w   <- ahp$weights[i]
      pct <- round(w*100,1)
      tags$tr(class="stat-row",
              tags$td(style="font-size:12px;padding:5px 8px;", crit[i]),
              tags$td(style="text-align:center;font-weight:700;padding:5px 8px;", paste0(pct,"%")),
              tags$td(style="padding:5px 8px;",
                      div(class="weight-bar-wrap",
                          div(class="weight-bar", style=paste0("width:",max(4,round(pct*2.8)),"px;")),
                          span(style="font-size:12px;color:#555;", round(w,4))
                      )
              )
      )
    })
    
    tagList(
      div(class="info-box", tab$desc),
      
      div(class="scale-box",
          h4("How to Score Each Comparison"),
          p(style="font-size:13px;color:#555;margin:0 0 12px;",
            "For each pair, ask: \u201CHow much more important is the ROW criterion compared to the COLUMN criterion?\u201D Choose the score that best matches your judgment. Use inverse values (1/2, 1/3\u2026) when the column is more important than the row."),
          div(class="scale-grid-desc",
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "1"),
                  div(class="scale-desc-text",
                      tags$b("Equal importance"),
                      tags$br(),
                      "Both criteria contribute equally. You have no reason to prefer one over the other."
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "2"),
                  div(class="scale-desc-text",
                      tags$b("Weak preference"),
                      tags$br(),
                      "The row criterion is slightly more important, but the difference is marginal and hard to justify strongly."
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "3"),
                  div(class="scale-desc-text",
                      tags$b("Moderate importance"),
                      tags$br(),
                      "Experience and judgment slightly favor the row criterion over the column. A noticeable but not overwhelming difference."
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "4"),
                  div(class="scale-desc-text",
                      tags$b("Moderate-strong preference"),
                      tags$br(),
                      "Between moderate and strong. Use when you feel the row is clearly more important but can\u2019t quite call it \u201Cstrong.\u201D"
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "5"),
                  div(class="scale-desc-text",
                      tags$b("Strong importance"),
                      tags$br(),
                      "The row criterion is strongly favored. Its importance is demonstrated in practice and the difference is significant."
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "6"),
                  div(class="scale-desc-text",
                      tags$b("Strong-very strong preference"),
                      tags$br(),
                      "Between strong and very strong. Use when a score of 5 feels too low but 7 feels too high."
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "7"),
                  div(class="scale-desc-text",
                      tags$b("Very strong importance"),
                      tags$br(),
                      "The row criterion is very strongly favored and its dominance is demonstrated in practice. The column criterion is far less critical."
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "8"),
                  div(class="scale-desc-text",
                      tags$b("Very strong\u2013absolute preference"),
                      tags$br(),
                      "Between very strong and absolute. Use when the evidence clearly supports near-absolute dominance of the row criterion."
                  )
              ),
              div(class="scale-desc-item",
                  span(class="scale-num-lg", "9"),
                  div(class="scale-desc-text",
                      tags$b("Absolute importance"),
                      tags$br(),
                      "The row criterion is overwhelmingly more important. This is the highest possible difference \u2014 use sparingly and only when fully justified."
                  )
              ),
              div(class="scale-desc-item scale-inverse-item",
                  span(class="scale-num-lg scale-inv-num", "1/x"),
                  div(class="scale-desc-text",
                      tags$b("Inverse scores (1/2 through 1/9)"),
                      tags$br(),
                      "If the COLUMN criterion is more important than the ROW, use the inverse. For example, select \u201C1/3\u201D if the column is moderately more important than the row."
                  )
              )
          )
      ),
      
      div(class="section-card",
          h3("Step 1: Pairwise Comparison Matrix"),
          p(style="font-size:13px;color:#555;margin-bottom:12px;",
            "For each upper-triangle cell, select how much more important the ROW criterion is vs. the COLUMN criterion. Lower-triangle cells auto-fill with the inverse."),
          div(style="overflow-x:auto;",
              tags$table(class="pairwise-table",
                         tags$thead(tags$tr(header_cells)),
                         tags$tbody(pair_rows)
              )
          ),
          tags$br(),
          actionButton("btn_reset", "\u21BA Reset Matrix", class="btn-reset"),
          downloadButton("btn_download", "\u2B07 Download Results (.xlsx)", class="btn-dl")
      ),
      
      div(class="section-card",
          h3("Step 2: Computed Weights"),
          tags$table(style="width:100%;border-collapse:collapse;",
                     tags$thead(tags$tr(
                       tags$th(style="text-align:left;padding:6px 8px;background:#1a3a4a;color:#fff;font-size:12px;","Criterion"),
                       tags$th(style="text-align:center;padding:6px;background:#1a3a4a;color:#fff;font-size:12px;","Weight %"),
                       tags$th(style="padding:6px;background:#1a3a4a;color:#fff;font-size:12px;","Bar")
                     )),
                     tags$tbody(weight_rows)
          )
      )
    )
  })
}

`%||%` <- function(a, b) if (is.null(a)) b else a

shinyApp(ui, server)