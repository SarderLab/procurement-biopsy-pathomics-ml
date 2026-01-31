# Author: Jeremy Rubin
# Date: 1/30/25
# Functions to help with things related to CKD distributions

### Function to classify CKD staging
classify_ckd <- function(egfr) {
  case_when(
    egfr >= 90 ~ "Stage 1 (≥90)",
    egfr >= 60 & egfr < 90 ~ "Stage 2 (60-89)",
    egfr >= 45 & egfr < 60 ~ "Stage 3a (45-59)",
    egfr >= 30 & egfr < 45 ~ "Stage 3b (30-44)",
    egfr >= 15 & egfr < 30 ~ "Stage 4 (15-29)",
    egfr < 15 ~ "Stage 5 (<15)",
    TRUE ~ NA_character_
  )
}

# Function to get CKD classification frequencies
get_ckd_frequencies <- function(egfr_vector) {
  # Define all possible CKD stages
  all_stages <- c(
    "Stage 1 (≥90)",
    "Stage 2 (60-89)",
    "Stage 3a (45-59)",
    "Stage 3b (30-44)",
    "Stage 4 (15-29)",
    "Stage 5 (<15)"
  )
  
  # Classify eGFR values
  classifications <- classify_ckd(egfr_vector)
  
  # Convert to factor with all possible levels
  classifications_factor <- factor(classifications, levels = all_stages)
  
  # Get frequencies with zeros for missing stages
  frequencies <- table(classifications_factor)
  
  return(frequencies)
}

#### Function to plot CKD distributions 
## Takes in a data frame where the first row is for the true eGFR, 
## second row is for the optimal random forest-predicted eGFR, 
## and the third row is the KDPI linear regression-predicted eGFR
## and the six columns from left to right are the six CKD stages 
## in ascending order
## also takes in a string that is "train" for training cohort 
## or "test" for testing cohort - updates string to print for title 
plot_CKD_distributions = function(CKD_df,cohort)
{
  # Setting plotting title depending on whether you're plotting CKD distribution
  # for training or testing cohort
  if(cohort=="train")
  {
    plot_title <- "Distribution of CKD Stages in Bootstrapped Training Transplanted Cohort"
  } else {
    plot_title <- "Distribution of CKD Stages in Hold-out Transplanted Cohort"
  }
  
  ckd_data <- data.frame(
    Stage = c("Stage 1 (≥90)", "Stage 2 (60-89)", "Stage 3a (45-59)",
              "Stage 3b (30-44)", "Stage 4 (15-29)", "Stage 5 (<15)"),
    True_eGFR = as.numeric(CKD_df[1,]),
    Random_Forest = as.numeric(CKD_df[2,]),
    KDPI = as.numeric(CKD_df[3,]) 
  )
  
  # Convert from wide to long format for ggplot
  ckd_long <- ckd_data %>%
    pivot_longer(
      cols = c(True_eGFR, Random_Forest, KDPI),
      names_to = "Method",
      values_to = "Frequency"
    )
  
  # Factor the Stage and Method variables to ensure correct ordering
  ckd_long$Stage <- factor(ckd_long$Stage,
                           levels = c("Stage 1 (≥90)", "Stage 2 (60-89)", "Stage 3a (45-59)",
                                      "Stage 3b (30-44)", "Stage 4 (15-29)", "Stage 5 (<15)"))
  ckd_long$Method <- factor(ckd_long$Method,
                            levels = c("KDPI", "Random_Forest", "True_eGFR"))
  
  # Create color mapping similar to your example
  method_colors <- c("KDPI" = "#FFA500", "Random_Forest" = "#FF4500", "True_eGFR" = "#4169E1")
  
  # Create a named vector for facet label renaming
  facet_labels <- c(
    "KDPI" = "Predicted eGFR (KDPI)",
    "Random_Forest" = "Predicted eGFR (Random Forest)", 
    "True_eGFR" = "True eGFR"
  )
  
  # Create the plot with facets by Method and use labeller to remove underscores
  ggplot(ckd_long, aes(x = Stage, y = Frequency, fill = Method)) +
    geom_bar(stat = "identity") +
    facet_grid(. ~ Method, scales = "free_x", labeller = labeller(Method = facet_labels)) +
    scale_fill_manual(values = method_colors) +
    labs(
      title = plot_title,
      x = "CKD Stage",
      y = "Number of subjects"
    ) +
    theme_minimal() +
    theme(
      # Reduced x-axis label size but still bold
      axis.text.x = element_text(angle = 0, hjust = 0.5, size = 10, face = "bold"),
      # Keep y-axis text large
      axis.text.y = element_text(size = 14, face = "bold"),
      # Keep axis titles large
      axis.title.x = element_text(size = 16, face = "bold", margin = ggplot2::margin(t = 25)),
      axis.title.y = element_text(size = 16, face = "bold", margin = ggplot2::margin(r = 20)),
      # Keep facet labels large
      strip.text = element_text(size = 18, face = "bold"),
      # Keep plot title large
      plot.title = element_text(hjust = 0.5, size = 24, face = "bold"),
      # Remove legend since we're faceting
      legend.position = "none",
      # Generous margins
      plot.margin = ggplot2::margin(b = 60, l = 20, r = 20, t = 20),
      # Panel spacing
      panel.spacing = unit(2, "lines")
    ) +
    # Use a slightly wider width for wrapping to make text smaller
    scale_x_discrete(labels = function(x) str_wrap(x, width = 8))  
}
