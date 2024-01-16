shinyUI(fluidPage(
  dashboardPage(
    dashboardHeader(title = "Detroit 911 Calls"),
    dashboardSidebar(
      dateRangeInput("date_picker_range", "Date Range", start = "2016-01-01", end = "2016-06-28"),
      selectInput("dropdown_category", "Category (Empty for All)", choices = sort(unique(result$category)), multiple = TRUE),
      selectInput("dropdown_period", "Period (Empty for All)", choices = unique(result$time_of_day), multiple = TRUE),
      selectInput("dropdown_day", "Day (Empty for All)", choices = c('lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche'), multiple = TRUE)
    ),
    dashboardBody(
      tabsetPanel(
        tabPanel("Presentation of our Dashboard",
          fluidRow(
            box(
              title = "Dataset Description",
              status = "primary",
              solidHeader = TRUE,
              collapsible = TRUE,
              width = 12,
              htmlOutput("dataset_description")
            )
          ),
          box(
            title = "Variable Descriptions",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 12,
            htmlOutput("variable_descriptions")
          ),
          box(
            title = "Dataset Preview",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 12,
            DTOutput("table")
          ),
          box(
            title = "About Us",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 12,
            htmlOutput("about_us")
          ),
          box(
            title = "Hafsa Boughemza",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 6,
            htmlOutput("hafsa_description")
          ),
          box(
            title = "Ryan Cassisi",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 6,
            htmlOutput("ryan_description")
          )
        ),
        tabPanel("Data",
                 tabsetPanel(
                   box(
                     title = "Best Units",
                     status = "primary",
                     solidHeader = TRUE,
                     collapsible = FALSE,
                     width = 4,
                     verbatimTextOutput("top_units")
                   ),
                   box(
                     title = "Average Times",
                     status = "info",
                     solidHeader = TRUE,
                     collapsible = FALSE,
                     width = 4,
                     "Intake Time", verbatimTextOutput("intake_mean_text"),
                     "Dispatch Time", verbatimTextOutput("dispatch_mean_text"),
                     "Travel Time", verbatimTextOutput("travel_mean_text"),
                     "Time on Scene", verbatimTextOutput("onscene_mean_text"),
                     "Total Time", verbatimTextOutput("total_mean_text"),
                     "",
                     plotlyOutput("times_pie_chart")
                   ),
                   box(
                     title = "Number of Calls",
                     status = "success",
                     solidHeader = TRUE,
                     collapsible = FALSE,
                     width = 4,
                     verbatimTextOutput("callscount")
                     
                  )
                 )
        ),
        tabPanel("Histogram",selectInput("column_select", "Choose a Column", choices = c('traveltime','intaketime','dispatchtime','timeonscene','totaltime'), selected = "traveltime"),
                 numericInput("upper_limit", "Upper Limit of Y-axis", value = 15000, min = 1, max = 50000),
                 tabsetPanel(
                   tabPanel("Grouped", plotOutput("histogram_plot_grouped")),
                   tabPanel("Individually", plotOutput("histogram_plot_Individually"))
                 )),
      
        tabPanel("Dispositions",
                 tabsetPanel(
                   tabPanel("Bar Chart", plotOutput("disposition_bar_chart")),
                   tabPanel("Line Chart",
                            selectInput("Month_select", "Choose a scale", choices = c('Daily','Monthly'), selected = "Monthly"),
                            tabsetPanel(
                              tabPanel("Line Chart", plotOutput("disposition_line_chart"))
                            )
                   )
                 )
        ),
        tabPanel("Line Chart",selectInput("Month_line_select", "Choose a disposition", choices = c('Daily','Monthly'), selected = "Monthly"),
                 tabsetPanel(
                  tabPanel("Grouped",  plotOutput("line_grouped")),
                  tabPanel("Separated",  plotOutput("line_separated")))       
                ),
        
        tabPanel("Map",tabsetPanel(
          tabPanel("Choropleth Map", leafletOutput("choropleth_map", width = "100%", height = "600px"))
          )       
      )
    )
  )
)
))