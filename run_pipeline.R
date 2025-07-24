# Load required libraries
library(spatstat)
library(clue)
library(dplyr)
library(stringr)

# Load your expression data
heavy_df <- read.csv("data/heavy_expression.csv")  # Adjust path as needed
light_df <- read.csv("data/light_expression.csv")

# Extract clone info
heavy_info <- clone_info_combined(heavy_df)
light_info <- clone_info_combined(light_df)

# Create point patterns
ppp_H <- create_ppp_from_clone_info(heavy_info)
ppp_L <- create_ppp_from_clone_info(light_info)

# Extract unique heavy and light clone IDs
H.id <- sort(unique(heavy_info$clone_id))
L.id <- sort(unique(light_info$clone_id))

# Compute spatial distance matrix
dist_mat <- spatial_distance_matrix(L.id, H.id, ppp_L, ppp_H, cutoff = 1000000)

# Normalize distance matrix
transformed_D <- transD(dist_mat)

# Load your mapping matrix from REPAIR output (example path)
mapping_matrix <- as.matrix(read.csv("data/mapping_matrix.csv", row.names = 1))

# Run pairing over omega values
omega_values <- seq(0, 1, by = 0.2)
pair_results <- pairs(omega_values, transformed_D, mapping_matrix, heavy.clone.id = rownames(mapping_matrix))

# Save results
write.csv(pair_results, "output/pairing_solutions.csv", row.names = FALSE)
