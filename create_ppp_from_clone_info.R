create_ppp_from_clone_info <- function(clone_df) {
  
  # Flip y-axis to match image orientation
  x_coords <- as.numeric(clone_df$x)
  y_coords <- -as.numeric(clone_df$y)
  
  # Define spatial window
  win <- owin(
    xrange = range(x_coords, na.rm = TRUE),
    yrange = range(y_coords, na.rm = TRUE)
  )
  
  # Drop x/y from marks
  marks_df <- clone_df
  marks_df$x <- NULL
  marks_df$y <- NULL
  
  # Create point pattern
  ppp_obj <- ppp(
    x = x_coords,
    y = y_coords,
    window = win,
    marks = marks_df
  )
  
  return(ppp_obj)
}