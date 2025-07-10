# ==============================================================================
# 🎨 ggplot2 Theme and Color Palette for the Project
# ==============================================================================
#
# This script defines a custom ggplot2 theme and a standardized color palette
# to ensure all visualizations in the project have a consistent, professional,
# and visually appealing look.
#
# Dependencies:
#   - ggplot2
#
# Functions:
#   - theme_esg(): A custom ggplot2 theme.
#   - esg_colors(...): A function to retrieve specific project colors.
#
# ==============================================================================

# Ensure ggplot2 is available
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("📦 Package 'ggplot2' is required for creating plots and themes.")
}

#' A Custom ggplot2 Theme for ESG Dissertation Project
#'
#' @description
#' This function applies a standardized, clean, and professional theme to ggplot objects.
#' It sets font sizes, background colors, grid lines, and other visual elements.
#'
#' @param base_size Base font size for the plot (default is 14).
#' @param base_family Base font family for the plot (default is "Helvetica").
#'
#' @return A ggplot2 theme object.
#' @export
theme_esg <- function(base_size = 14, base_family = "Helvetica") {
  
  # Start with a minimal theme and customize it
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) %+replace%
    ggplot2::theme(
      # --- Plot Title and Subtitle ---
      plot.title = ggplot2::element_text(
        size = rel(1.4), # Relative size to base_size
        face = "bold",
        hjust = 0, # Left-align
        margin = ggplot2::margin(b = 15) # Margin at the bottom
      ),
      plot.subtitle = ggplot2::element_text(
        size = rel(1.1),
        hjust = 0,
        margin = ggplot2::margin(b = 20)
      ),
      
      # --- Axis Customization ---
      axis.title = ggplot2::element_text(size = rel(1.0), face = "bold"),
      axis.text = ggplot2::element_text(size = rel(0.9), color = "grey40"),
      axis.line = ggplot2::element_line(color = "grey80"),
      
      # --- Grid Lines ---
      panel.grid.major = ggplot2::element_line(color = "grey90", linetype = "dashed"),
      panel.grid.minor = ggplot2::element_blank(), # No minor grid lines
      
      # --- Legend ---
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_text(face = "bold", size = rel(0.9)),
      legend.text = ggplot2::element_text(size = rel(0.85)),
      
      # --- Facet (for multi-panel plots) ---
      strip.background = ggplot2::element_rect(fill = "grey95", color = NA),
      strip.text = ggplot2::element_text(face = "bold", size = rel(1.0)),
      
      # --- General Plot Area ---
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.caption = ggplot2::element_text(hjust = 1, size = rel(0.8), color = "grey50")
    )
}


#' Standardized Color Palette for the Project
#'
#' @description
#' A function to retrieve consistent hexadecimal color codes for specific categories.
#' Using this ensures that, e.g., "Upgrade" is always the same green in every plot.
#'
#' @param ... Character strings corresponding to the names of the desired colors.
#'
#' @return A named character vector of hex color codes.
#' @export
esg_colors <- function(...) {
  
  # Define the master color palette
  color_palette <- c(
    `upgrade`           = "#009E73",  # A nice teal/green
    `downgrade`         = "#D55E00",  # A vermillion/red
    `neutral`           = "#999999",  # Medium grey
    `long_short`        = "#0072B2",  # A nice blue
    `strong_policy`     = "#56B4E9",  # A sky blue
    `weak_policy`       = "#E69F00",  # An orange
    `recession_shade`   = "#F0F0F0",  # Light grey for shading
    `main_line`         = "#333333"   # Dark grey for general lines
  )
  
  # If no names are provided, return the full palette
  if (nargs() == 0) {
    return(color_palette)
  }
  
  # Otherwise, return the requested colors
  requested_colors <- c(...)
  return(color_palette[requested_colors])
}


# --- Set the custom theme as the default for all subsequent plots in the session ---
ggplot2::theme_set(theme_esg())


# --- Script loaded confirmation ---
cat("✅ Custom ggplot2 theme (`theme_esg`) and color palette (`esg_colors`) loaded and set as default.\n")