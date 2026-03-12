spatial_distance_matrix <- function(L.id, H.id, ppp_L, ppp_H, cutoff=1e+06) {
  # Initialize output matrix
  dist_matrix <- matrix(NA, nrow = length(L.id), ncol = length(H.id))
  rownames(dist_matrix) <- L.id
  colnames(dist_matrix) <- H.id
  
  # Loop through each pair of light and heavy clones
  for (j in seq_along(L.id)) {
    point_pattern_L <- subset(ppp_L, clone_id == L.id[j])
    
    for (k in seq_along(H.id)) {
      point_pattern_H <- subset(ppp_H, clone_id == H.id[k])
      
      distpp <- tryCatch({
        pppdist(point_pattern_H, point_pattern_L, type = "mat", matching = FALSE, auction = FALSE, cutoff = cutoff)
      }, error = function(e) {
        0
      })
      
      dist_matrix[j, k] <- distpp
    }
  }
  
  # Transpose to make rows = heavy, columns = light (as in your original code)
  dist_matrix <- t(dist_matrix)
  return(dist_matrix)
}
