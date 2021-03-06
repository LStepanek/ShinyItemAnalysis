# DATA CHECKING ####
# * Error and warning messages for upload ####
checkDataText_Input <- eventReactive(input$submitButton, {
  error_setting <- F

  if (dataset$data_status == "missing"){
    str_errors <- "No data found! Please, upload data. Default dataset GMAT is now in use."
    str_warnin <- ""
  } else {
    ### key
    error_key <- ""
    if (length(dataset$key) == 1){
      if (dataset$key == "missing"){
        error_key <- "The key need to be provided!"
      }
    } else {
      if (ncol(dataset$answers) != length(dataset$key)){
        error_key <- "The length of key need to be the same as number of columns of the main dataset!"
        error_setting <- T
      }
    }
    ### group
    error_group <- ""
    warni_group <- ""
    if (any(dataset$group == "missing", na.rm = T)){
      warni_group <- "The group variable is not provided! DIF and DDF analyses are not available!"
    } else {
      if (nrow(dataset$answers) != length(dataset$group)){
        error_group <- "The length of group need to be the same as number of observations in the main dataset!"
        error_setting <- T
      }
    }
    ### criterion variable
    error_criterion_variable <- ""
    warni_criterion_variable <- ""
    if (any(dataset$criterion_variable == "missing", na.rm = T)){
      warni_criterion_variable <- "The criterion variable is not provided! Predictive validity analysis is not available!"
    } else {
      if (nrow(dataset$answers) != length(dataset$criterion_variable)){
        error_criterion_variable <- "The length of criterion variable need to be the same as number of observations in the main dataset!"
        error_setting <- T
      }
    }

    str_errors <- c(error_key, error_group, error_criterion_variable)
    str_warnin <- c(warni_group, warni_criterion_variable)
  }


  if (any(str_warnin != "")){
    str_warnin <- str_warnin[str_warnin != ""]
    str_warnin <- paste("<font color = 'orange'> &#33;", str_warnin, "</font>", collapse = "<br>")
  }

  if(all(str_errors == "")){
    paste(c("<font color = 'green'> &#10004; Your data were successfully uploaded. Check them in <b>Data exploration</b> tab. </font>",
            str_warnin), collapse = "<br>")
  } else {
    str_errors <- str_errors[str_errors != ""]
    str_errors <- paste("<font color = 'red'> &#10006;", str_errors, "</font>", collapse = "<br>")
    if (error_setting){
      paste(c(str_errors,
              "<font color = 'red'> Check <b>Data exploration</b> tab to get idea what went wrong or try another
              <b>Data specification</b> below. </font>"),
            collapse = "<br>")
    } else {
      paste(str_errors)
    }
  }
})
output$checkDataText <- renderUI({
  HTML(checkDataText_Input())
})

# * Checking uploaded scored data ####
checkDataColumns01_Input <- reactive({
  data <- correct_answ()
  # are there any items with only 0
  all0 <- apply(data, 2, function(x) all(x == 0))
  all1 <- apply(data, 2, function(x) all(x == 1))

  list(all0 = all0, all1 = all1)
})

# * Render button for excluding such items ####
output$renderdeleteButtonColumns01 <- renderUI({
  all0 <- checkDataColumns01_Input()$all0
  all1 <- checkDataColumns01_Input()$all1

  if (input$submitButton & (any(all0) | any(all1))){
    tagList(
      actionButton(inputId = "deleteButtonColumns01",
                   label = "Remove items",
                   class = "btn btn-large btn-primary",
                   icon = icon("trash"),
                   width = "150px")
    )
  }
})

# # * Removing such items ####
# eventReactive(input$deleteButtonColumns01, {
#   ok0 <- (!checkDataColumns01_Input()$all0)
#   ok1 <- (!checkDataColumns01_Input()$all1)
#
#   dataset$answers <- dataset$answers[, (ok0 & ok1)]
#   dataset$key <- dataset$key[(ok0 & ok1)]
#
# })

# * Text for check of uploaded scored data ####
checkDataColumns01Text_Input <- eventReactive(input$submitButton, {
  all0 <- checkDataColumns01_Input()$all0
  all1 <- checkDataColumns01_Input()$all1

  if (any(all0)){
    txt0 <- paste("It seems that",
                  item_names()[all0],
                  "consists only of zeros.")
  } else {
    txt0 <- ""
  }
  if (any(all1)){
    txt1 <- paste("It seems that",
                  item_names()[all1],
                  "consists only of ones.")
  } else {
    txt1 <- ""
  }

  # warning
  if (any(all0) | any(all1)){
    txt <- paste(c("Check your data!",
                   paste(txt0, collapse = "<br>"),
                   paste(txt1, collapse = "<br>"),
                   "Some analyses may not work properly. Consider removing such items.
                   For this purpose you can use button <b>Remove items</b> on the right side. <br><br>"),
                 collapse = "<br>")
    txt <- paste("<font color = 'red'>", txt, "</font>")
  } else {
    txt <- ""
  }

  txt
})
output$checkDataColumns01Text <- renderUI({
  HTML(checkDataColumns01Text_Input())
})

# * Checking uploaded group membership ####
checkGroup_Input <- reactive({
  group <- DIF_groups()
  # are there any missing values?
  NAgroup <- is.na(group)
  NAgroup
})

# * Text for check of uploaded group membership ####
checkGroupText_Input <- eventReactive(input$submitButton, {
  NAgroup <- checkGroup_Input()

  if (any(NAgroup)){
    txt <- paste(sum(NAgroup),
                 ifelse(sum(NAgroup) == 1,
                        "observation has",
                        "observations have"),
                 "missing group membership. <br>
                 Some analyses may not work properly. Consider removing such items.
                 For this purpose you can use button <b>Remove data</b> on the right side. <br><br>")
    txt <- paste("<font color = 'red'>", txt, "</font>")
  } else {
    txt <- ""
  }
  txt
})

output$checkGroupText <- renderUI({
  HTML(checkGroupText_Input())
})

# # * Removing such data ####
# eventReactive(input$deleteButtonGroup, {
#   OKgroup <- !checkGroup_Input()
#
#   dataset$answers <- dataset$answers[OKgroup, ]
#   dataset$group <- dataset$group[OKgroup]
#   dataset$criterion_variable <- dataset$criterion_variable[OKgroup]
# })

# * Render button for excluding data with missing group membership ####
output$renderdeleteButtonGroup <- renderUI({
  NAgroup <- checkGroup_Input()

  if (input$submitButton & any(NAgroup)){
    tagList(
      actionButton(inputId = "deleteButtonGroup",
                   label = "Remove data",
                   class = "btn btn-large btn-primary",
                   icon = icon("trash"),
                   width = "150px")
    )
  }
})

# DATA DESCRIPTION ####
data_description_Input <- reactive({
  data_name <- input$dataSelect
  txt <- switch(data_name,
                GMAT_difNLR = "<code>GMAT</code> <a href='https://doi.org/10.1187/cbe.16-10-0307' target='_blank'>
                (Martinkova, et al., 2017) </a> is generated dataset based on parameters of real Graduate Management
                Admission Test (GMAT; Kingston et al., 1985). However, first two items were simulated to function
                differently in uniform and non-uniform way respectively. The dataset represents responses of 2,000 subjects
                (1,000 males, 1,000 females) to multiple-choice test of 20 items. The distribution of total scores is the
                same for both groups. See <a href='https://doi.org/10.1187/cbe.16-10-0307' target='_blank'> Martinkova, et al.
                (2017)</a> for further discussion. <code>GMAT</code> also containts simulated continuous criterion variable. ",
                GMAT2_difNLR = "<code>GMAT2</code> (Drabinova & Martinkova, 2017) is simulated dataset based on parameters
                of real Graduate Management Admission Test (GMAT; Kingston et al., 1985) from <code>difNLR</code> R package .
                First two items were simulated to function differently in uniform and non-uniform way respectively.
                The dataset represents responses of 1,000 subjects (500 males, 500 females) to multiple-choice test of 20
                items. ",
                MSATB_difNLR = "<code>MSAT-B</code> (Drabinova & Martinkova, 2017) is a subset of real Medical School
                Admission Test in Biology (MSAT-B) in Czech Republic from <code>difNLR</code> R package. The dataset
                represents responses of 1,407 subjects (484 males, 923 females) to multiple-choice test of 20 items.
                First item was previously detected as functioning differently. For more details of item selection see
                Drabinova and Martinkova (2017). ",
                dataMedical_ShinyItemAnalysis = "<code>Medical 100</code> is a real dataset of admission test to medical
                school from <code>ShinyItemAnalysis</code> R package. The data set represents responses of 2,392 subjects
                (750 males, 1,633 females and 9 subjects without gender specification) to multiple-choice test of 100
                items. <code>Medical 100</code> contains criterion variable - indicator whether student studies standardly
                or not. ",
                HCI_ShinyItemAnalysis = "<code>HCI</code> (McFarland et al., 2017) is a real dataset of Homeostasis
                Concept Inventory (HCI) from <code>ShinyItemAnalysis</code> R package. The dataset represents responses of
                651 subjects (405 males, 246 females) to multiple-choice test of 20 items. <code>HCI</code> contains
                criterion variable -  indicator whether student plans to major in the life sciences. ")
  txt

})

output$data_description <- renderUI({
  HTML(data_description_Input())
})

# BASIC SUMMARY ####

# * Main dataset ####
# ** Dimension ####
output$data_rawdata_dim <- renderText({
  txt <- paste0("Dataset consists of ", nrow(test_answers()), " observations on the ", ncol(test_answers()), " items. ")
})

# ** Summary ####
data_rawdata_summary_Input <- reactive({
  data_table <- test_answers()
  data_table <- sapply(data_table, as.factor)
  colnames(data_table) <- item_names()
  summary(data_table)
})

output$data_rawdata_summary <- renderPrint({
  data_rawdata_summary_Input()
})

# * Scored test ####
data_scoreddata_summary_Input <- reactive({
  data_table <- correct_answ()
  data_table <- sapply(data_table, as.factor)
  colnames(data_table) <- item_names()
  summary(data_table)
})

output$data_scoreddata_summary <- renderPrint({
  data_scoreddata_summary_Input()
})

# * Group ####
data_group_summary_Input <- reactive({
  gr <- as.factor(DIF_groups())
  summary(gr)
})

output$data_group_summary <- renderPrint({
  data_group_summary_Input()
})

# * Criterion ####
data_criterion_summary_Input <- reactive({
  summary(criterion_variable())
})

output$data_criterion_summary <- renderPrint({
  data_criterion_summary_Input()
})
