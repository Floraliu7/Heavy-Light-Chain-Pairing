clone_info_combined <- function(df, img.scale = 1) {
  clones_info <- list()
  
  # Auto-detect coordinate columns
  coord_names <- colnames(df)[2:3]
  if (all(c("imagerow", "imagecol") %in% coord_names)) {
    y_col <- "imagerow"  # vertical
    x_col <- "imagecol"  # horizontal
  } else if (all(c("y", "x") %in% coord_names)) {
    y_col <- "y"
    x_col <- "x"
  } else {
    stop("Could not detect coordinate columns (expected imagerow/imagecol or y/x).")
  }
  
  # Loop through clones
  for (i in 4:ncol(df)) {
    clone_data <- df[df[, i] > 0, ]
    clone_id <- colnames(df)[i]
    
    if (nrow(clone_data) > 0) {
      clone_data <- cbind(
        x = as.numeric(clone_data[[x_col]]) * img.scale,
        y = as.numeric(clone_data[[y_col]]) * img.scale,
        n = as.numeric(clone_data[, i])
      )
      clone_data <- as.data.frame(clone_data, stringsAsFactors = FALSE)
      clone_data$clone_id <- as.numeric(gsub("[^0-9]", "", clone_id))
      clone_data$clone_id_rank <- clone_id
      
      clones_info[[clone_id]] <- clone_data
    }
  }
  
  # Combine all clones into one big data frame
  combined_info <- do.call(rbind, clones_info)
  rownames(combined_info) <- NULL  # reset rownames
  return(combined_info)
}