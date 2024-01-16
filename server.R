shinyServer(function(input, output, session) {
  
  # Récupération des valeurs des filtres
  selected_categories <- reactive({
    input$dropdown_category
  })
 
  ## Paramètres de filtrage
  start_date <- reactive({
    input$date_picker_range[1]
  })
  
  end_date <- reactive({
    input$date_picker_range[2]
  })
  
  selected_periods <- reactive({
    input$dropdown_period
  })
  
  selected_days <- reactive({
    input$dropdown_day
  })
  
  # Filtrage de la dataframe en fonction des filtres
  filtered_data <- reactive({
    data_filtered <- result
    if (!is.null(selected_categories())) {
     data_filtered <- data_filtered[data_filtered$category %in% selected_categories(), ]
   }
    if (!is.null(start_date()) && !is.null(end_date())) {
    data_filtered <- data_filtered[data_filtered$calldate >= start_date() & data_filtered$calldate <= end_date(), ]
   }
   if (!is.null(selected_periods())) {
     data_filtered <- data_filtered[data_filtered$time_of_day %in% selected_periods(), ]
  }
   if (!is.null(selected_days())) {
     data_filtered <- data_filtered[data_filtered$day_of_week %in% selected_days(), ]
   }
   return(data_filtered)
  })
  
  # Define the render_mean_text function
  render_mean_text <- function(label, variable) {
    data <- filtered_data()  # Assuming you have a filtered_data() function
    mean_value <- mean(data[[variable]])
    paste(label, "Mean: ", round(mean_value, 2))
  }
  
  # Carte choropleth
  output$choropleth_map <- renderLeaflet({
    data <- filtered_data()  # Utiliser le dataframe filtré
    
    dt <- as.data.table(data) 
    calls_by_zipcode <- dt[, .(call_count = .N), by = .(zipcode)]
    calls_by_zipcode <- calls_by_zipcode[order(-call_count)]
    merged_data <- zipcode_gdf %>%
      left_join(calls_by_zipcode, by = "zipcode")
    
    # Créez une carte Leaflet
    center <- c(42.36873, -83.07779)
    colors <- colorQuantile("Reds", domain = merged_data$call_count)
    values <- quantile(merged_data$call_count, probs = seq(0, 1, 0.2))
    
    leaflet() %>%
      setView(lng = center[2], lat = center[1], zoom = 12) %>%
      addTiles() %>%
      addPolygons(data = merged_data, 
                  fillColor = ~colorQuantile("Reds", domain = merged_data$call_count)(call_count),
                  fillOpacity = 0.7,
                  color = "white",
                  weight = 1,
                  popup = ~as.character(call_count)) %>%
      addLegend(position = "bottomright", pal = colors, values = values, title = "Number of calls")
  })

  
  # Détermine les 3 meilleurs unités
  output$top_units <- renderPrint({
  data <- filtered_data()  # Utiliser le dataframe filtré
  dt <- as.data.table(data) 
  
  # Calculer les trois premières unités répondantes
  calls_by_respondingunit <- dt[, .(call_count = .N), by = .(respondingunit)]
  calls_by_respondingunit <- calls_by_respondingunit[order(-call_count)]
  calls_by_respondingunit <- calls_by_respondingunit[respondingunit != ""]
  # Vérifier si le nombre d'unités répondantes est inférieur à 3
  if (nrow(calls_by_respondingunit) < 3) {
    # Remplacer les unités manquantes par des valeurs vides
    for (i in (nrow(calls_by_respondingunit) + 1):3) {
      calls_by_respondingunit <- rbind(calls_by_respondingunit, data.table(respondingunit = "", call_count = 0))
    }
  }
  
  top_3_units <- head(calls_by_respondingunit, 3)
  
  # Filtrer les unités répondantes non vides
  
  # Créer un vecteur avec les positions et les noms d'unités pour l'affichage
  positions <- c("1st", "2nd", "3rd")
  top_3_units$position <- positions
  top_3_units$display <- paste(top_3_units$position, ": ", top_3_units$respondingunit)
  
  # Afficher les résultats dans la sortie "top_units"
  cat(paste(top_3_units$display, collapse = "\n"))
  })
  
  # Rendu du texte pour le TabPanel "Calls Count"
  output$callscount <- renderText({
    data <- filtered_data()  # Utiliser le dataframe filtré
    
    number_of_calls <- nrow(data)
    formatted_number <- format(number_of_calls, big.mark = " ")
    paste("Number of calls : ", formatted_number)
  })
  
  ## Calculs des temps moyens
  output$intake_mean_text <- renderText({
    data <- filtered_data() 
    intakeMean <- mean(data$intaketime)
    paste("Intake Mean: ", round(intakeMean, 2), "min")
  })
  
  output$dispatch_mean_text <- renderText({
    data <- filtered_data() 
    dispatchMean <- mean(data$dispatchtime)
    paste("Dispatch Mean: ", round(dispatchMean, 2), "min")
  })
  
  output$travel_mean_text <- renderText({
    data <- filtered_data() 
    travelMean <- mean(data$traveltime)
    paste("Travel Mean: ", round(travelMean, 2), "min")
  })
  
  output$onscene_mean_text <- renderText({
    data <- filtered_data() 
    onsceneMean <- mean(data$timeonscene)
    paste("On Scene Mean: ", round(onsceneMean, 2), "min")
  })
  
  output$total_mean_text <- renderText({
    data <- filtered_data() 
    totalMean <- mean(data$totaltime)
    paste("Total Mean: ", round(totalMean, 2), "min")
  })
  # Pie chart des temps
  output$times_pie_chart <- renderPlotly({
    data <- filtered_data()
    
    # Calcule les temps moyens
    intakeMean <- mean(data$intaketime)
    dispatchMean <- mean(data$dispatchtime)
    travelMean <- mean(data$traveltime)
    onsceneMean <- mean(data$timeonscene)
    
    # Crée un dataframe pour le pie chart
    pie_data <- data.frame(
      Time = c("Intake", "Dispatch", "Travel", "On Scene"),
      Mean = c(intakeMean, dispatchMean, travelMean, onsceneMean)
    )
    
    # Creation du piechart
    pie_chart <- plot_ly(
      data = pie_data,
      labels = ~Time,
      values = ~Mean,
      type = "pie",
      textinfo = "percent+label",
      hole = 0.6
    )
    
    # Customisation du layout
    pie_chart <- pie_chart %>% layout(title = "Mean Times Distribution")
    
    # Retourne le pie chart
    pie_chart
  })
 
  
  ##Présentation du dashboard
  output$dataset_description <- renderUI({
    HTML(
    "This table shows all 9-1-1 police emergency response and officer-initiated calls for service in the City of Detroit beginning January 1, 2016.<br><br>
  Emergency response calls are the result of people calling 9-1-1 to request police services. Officer-initiated calls include traffic stops, street investigations and other policing activities (such as observing crimes in progress) where police officers initiate the response.<br><br>
  The table includes all calls taken and reports intake, dispatch, travel, and total response and call times for those calls serviced by a police agency. The data also includes the responding agency, unit, call type and category and disposition of each call.<br><br>
  The location data is provided to the block-level by anonymizing the last two digits of the incident address and offsetting the longitude/latitude coordinates. The times are presented in fractional minutes (e.g., 1.5 min = 1 min 30 secs). The table is updated every 20 minutes.<br><br>"
    )
    })
  
  output$variable_descriptions <- renderUI({
    HTML("
  - <b>callno</b> - call number in records management system<br>
  - <b>agency</b> - responding agency (DPD, WSUPD, HIGHLAND PARK, DET PUB SCHOOLS)<br>
  - <b>incident_address</b> - location of incident<br>
  - <b>callcode</b> - numeric call code/type<br>
  - <b>calldescription</b> - description of emergency/call type<br>
  - <b>category</b> - category of type (Family Trouble, Assault, Robbery, etc)<br>
  - <b>calldate</b> - date of incident<br>
  - <b>calltime</b> - time of incident<br>
  - <b>disposition</b> - disposition (arrest, report taken, etc.)<br>
  - <b>precinctSCA</b> - DPD Precinct and Scout Car Area (geographic)<br>
  - <b>respondingunit</b> - car code of responding unit<br>
  - <b>officerinitiated</b> - yes/no, whether run was an officer-initiated/onview run<br>
  - <b>intaketime</b> - minutes for call intake, handoff to dispatcher<br>
  - <b>dispatchtime</b> - minutes elapsed until the first unit is dispatched<br>
  - <b>traveltime</b> - minutes elapsed from dispatch to unit onscene<br>
  - <b>totresponsetime</b> - total time elapsed from call dispatch time to call close time<br>
  - <b>timeonscene</b> - minutes elapsed from unit onscene to call close time<br>
  - <b>totaltime</b> - total time elapsed from call created time to call close time<br>
  - <b>day_of_week</b> - The day of the week on which the incident occurred (e.g., Monday, Tuesday, etc.).<br>
  - <b>time_of_day</b> - The general time of day when the incident occurred, categorized as morning, afternoon, evening, or night.<br>
  - <b>zipcode</b> - The postal code associated with the incident location.<br>"
    )
    
  })
  
  output$about_us <- renderUI({
    HTML("We are a team of two students from the engineering school <a href='https://www.esiee.fr/en'><b>ESIEE Paris</b></a>, specializing in <b>\"Data Science and Artificial Intelligence.\"</b><br>
         This project is a collaborative effort as part of our coursework on \"Data Visualization with Python,\"<br>
         under the guidance of our teacher, <b>Daniel Courivaud</b>."
    )
  })
  
  output$hafsa_description <- renderUI({
    HTML("Hello, it's Hafsa! I am passionate about computer science and artificial intelligence.<br>
         Beside coding, I'm all about fitness !"
    )
  })
  
  output$ryan_description <- renderUI({
    HTML("Hello, I'm Ryan! A tech enthusiast with a deep passion for artificial intelligence.<br>
         Outside the world of code, I'm a sports fan, particularly devoted to soccer. Huge fan of PSG !"
    )
  })
 
  output$table <- renderDT({
    data <- filtered_data()
    datatable(
      as.data.frame(data),
      options = list(
        pageLength = 10,
        dom = 'tip',
        lengthMenu = c(10, 20, 50),
        autoWidth = TRUE,
        scrollX =TRUE
      ),
      rownames = FALSE,
      class = "display"
    )
  })
  
  ## Histogrammes
  output$histogram_plot_grouped <- renderPlot({
    data <- filtered_data() 
    
    hist_data <- hist(data[[input$column_select]], plot = FALSE)
    max_frequency <- max(hist_data$counts)
    
    ggplot(data, aes(x = .data[[input$column_select]]) ) +
      geom_histogram(binwidth = 1, color = "black", fill = "lightblue") +
      xlim(0, 30) +
      labs(title = "Histogram of Selected Time",
           x = "Selected Time",
           y = "Frequency") +
      theme_dark() +
      coord_cartesian(ylim = c(0, input$upper_limit))
    
  })
  
  output$histogram_plot_Individually <- renderPlot({
    data <- filtered_data() 
    
    hist_data <- hist(data[[input$column_select]], plot = FALSE)
    max_frequency <- max(hist_data$counts)
    
    ggplot(data, aes(x = .data[[input$column_select]], fill = category)) +
      geom_histogram(binwidth = 1, color = "black") +
      xlim(0, 30) +
      labs(title = "Histogram of Selected Time",
           x = "Selected Time",
           y = "Frequency") +
      theme_dark() +
      coord_cartesian(ylim = c(0, input$upper_limit)) +
      scale_fill_discrete(name = "Category")
  })
  
  ## Dispositions
  output$disposition_bar_chart <- renderPlot({
    data <- filtered_data() 
    dt <- as.data.table(data) 
    
    calls_by_disposition <- dt[, .(call_count = .N), by = .(disposition)]
    calls_by_disposition  <- calls_by_disposition  %>% arrange(desc(call_count))
    calls_by_disposition <- calls_by_disposition[disposition  != ""]
    calls_by_disposition$disposition <- factor(calls_by_disposition$disposition, levels = rev(calls_by_disposition$disposition))
    
    ggplot(calls_by_disposition, aes(x =disposition , y = call_count)) +
      geom_bar(stat = "identity", fill = "skyblue") +
      theme_minimal() +
      labs(title = "Bar Chart of Dispositions", x = "disposition", y = "Call Count") +
      coord_flip()
    
  })
  
  output$disposition_line_chart <- renderPlot({
    data <- filtered_data() 
    # On extrait le mois si l'échelle monthly est sélectionnée
    if (input$Month_select == "Monthly") {
      data$month <- month(data$calldate)
      dt <- as.data.table(data) 
      
      calls_by_disposition <- dt[, .(call_count = .N), by = .(disposition, month)]
      calls_by_disposition  <- calls_by_disposition  %>% arrange(desc(call_count))
      calls_by_disposition <- calls_by_disposition[disposition  != ""]
      
      ggplot(calls_by_disposition , aes(x = month, y = call_count, color = disposition)) +
        geom_line() +
        theme_minimal() +
        labs(title = "Line Chart of Dispositions over Time", x = "Date", y = "Call Count") +
        scale_color_brewer(palette = "Set1")
    }
    else {
      dt <- as.data.table(data) 
      
      calls_by_disposition <- dt[, .(call_count = .N), by = .(disposition, calldate)]
      calls_by_disposition  <- calls_by_disposition  %>% arrange(desc(call_count))
      calls_by_disposition <- calls_by_disposition[disposition  != ""]
      
      ggplot(calls_by_disposition , aes(x = calldate, y = call_count, color = disposition)) +
        geom_line() +
        theme_minimal() +
        labs(title = "Line Chart of Dispositions over Time", x = "Date", y = "Call Count") +
        scale_color_brewer(palette = "Set1")
    }
    
 
    
  })
  
  output$line_grouped <- renderPlot({
    data <- filtered_data() 
    if (input$Month_line_select == "Monthly") {
      data$month <- month(data$calldate)
      dt <- as.data.table(data) 
      
      calls_by_calldate <- dt[, .(call_count = .N), by = .(month)]
      calls_by_calldate  <- calls_by_calldate  %>% arrange(desc(call_count))
      
      ggplot(calls_by_calldate , aes(x = month, y = call_count)) +
        geom_line() +
        theme_minimal() +
        labs(title = "Line Chart of Dispositions over Time", x = "Date", y = "Call Count") +
        scale_color_brewer(palette = "Set1")
      
    }
    else{
      dt <- as.data.table(data) 
      
      calls_by_calldate <- dt[, .(call_count = .N), by = .(calldate)]
      calls_by_calldate  <- calls_by_calldate  %>% arrange(desc(call_count))
      
      ggplot(calls_by_calldate , aes(x = calldate, y = call_count)) +
        geom_line() +
        theme_minimal() +
        labs(title = "Line Chart of Dispositions over Time", x = "Date", y = "Call Count") +
        scale_color_brewer(palette = "Set1")
      
    }

  })
  
  output$line_separated <- renderPlot({
    data <- filtered_data() 
    if (input$Month_line_select == "Monthly") {
      data$month <- month(data$calldate)
      dt <- as.data.table(data) 
      
      calls_by_calldate <- dt[, .(call_count = .N), by = .(category, month)]
      calls_by_calldate  <- calls_by_calldate  %>% arrange(desc(call_count))
      
      ggplot(calls_by_calldate , aes(x = month, y = call_count, color = category)) +
        geom_line() +
        theme_minimal() +
        labs(title = "Line Chart of Dispositions over Time", x = "Date", y = "Call Count") +
        scale_color_brewer(palette = "Set1")
    }
    else{
      dt <- as.data.table(data) 
      
      calls_by_calldate <- dt[, .(call_count = .N), by = .(category, calldate)]
      calls_by_calldate  <- calls_by_calldate  %>% arrange(desc(call_count))
      
      ggplot(calls_by_calldate , aes(x = calldate, y = call_count, color = category)) +
        geom_line() +
        theme_minimal() +
        labs(title = "Line Chart of Dispositions over Time", x = "Date", y = "Call Count") +
        scale_color_brewer(palette = "Set1")
    }

    
  })
   
})


