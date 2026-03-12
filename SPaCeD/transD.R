transD <- function(dist_matrix) {
  dist_matrix <- as.matrix(dist_matrix)  # ensure it's a matrix
  numerator <- exp(-dist_matrix)
  
  # Row-wise normalization with sweep
  denominator <- rowSums(numerator)
  
  # Avoid divide-by-zero by setting zeros to 1 temporarily
  denominator[denominator == 0] <- 1
  
  result <- sweep(numerator, 1, denominator, FUN = "/")
  
  return(result)
}
