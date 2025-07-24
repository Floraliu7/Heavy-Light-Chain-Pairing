pairs <- function(w, transD, mapping_matrix,H.id){
  pairs <- matrix(nrow=length(H.id), ncol=length(w))
  for (i in 1:length(w)){
    obj <- w[i]*transD+(1-w[i])*mapping_matrix
    
    sol <- solve_LSAP(obj, maximum = TRUE)
    pairs[,i] <- as.numeric(unlist(sol))
    for (j in 1:length(H.id)){
      light_ids <- as.numeric(colnames(mapping_matrix))
      pairs[j,i] <- light_ids[pairs[j,i]]
    }
  }
  pairs <- cbind(as.matrix(rownames(mapping_matrix)), pairs)
  colnames(pairs) <- c("heavy_ids", c(paste("w=", w, sep = "")))
  pairs <- as.data.frame(pairs)
  
  return(pairs)
}