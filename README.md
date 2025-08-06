## Spatial Pairing Algorithm

Our method uses a **spatial pairing algorithm** that maximizes the following objective using a **linear assignment problem**:

<img width="390" height="63" alt="Screenshot 2025-07-30 at 19 55 35" src="https://github.com/user-attachments/assets/3d42e7a3-66a8-4cd7-b124-11cb68943896" />


Where:
- <img width="25" height="25" alt="Screenshot 2025-07-30 at 19 57 01" src="https://github.com/user-attachments/assets/74333f22-20ef-41ab-8ed0-34ad5ae3be18" /> is a **binary variable**: 1 if heavy chain *i* is paired with light chain *j*, 0 otherwise.
- <img width="25" height="26" alt="Screenshot 2025-07-30 at 19 57 12" src="https://github.com/user-attachments/assets/ccd7deee-1f28-437f-9914-eacd0dca58b0" /> is a **tuning parameter** that balances spatial distance and expression similarity.
- <img width="46" height="49" alt="Screenshot 2025-07-30 at 19 57 18" src="https://github.com/user-attachments/assets/446deac9-2b45-4dce-9ac4-8e620f0c2f72" /> is the **normalized spatial distance** between chain *i* and *j*:
- <img width="51" height="40" alt="Screenshot 2025-07-30 at 19 57 28" src="https://github.com/user-attachments/assets/0aa3b70c-7af2-432f-bb94-9ef017f7f4d0" /> is the **mapping matrix** learned from the REPAIR model, representing how much light chain *j* contributes to the expression of heavy chain *i*.

To run REPAIR and generate `M`, follow the full guide provided in the official REPAIR repository:

👉 [https://github.com/almaan/star-repair](https://github.com/almaan/star-repair)

This framework allows us to balance **spatial proximity** and **expression evidence** for robust pairing.

---

## Data Preparation Guide

To apply this tool to your own dataset, you will need to prepare a single combined **data frame** that includes both spatial and gene expression information.

### Step 1: Create Spatial Barcode Table

Your dataset must include the spatial location of each barcode, with the following columns:

- `barcodes`: spatial barcode (on tissue location ID)
- `imagerow` and `imagecol`: integer pixel positions in the image (used to define spatial coordinates)

This will later be used to create a **point pattern object** for spatial analysis.

**Example:**

| barcodes           | imagerow | imagecol |
|--------------------|----------|----------|
| AAACCTGAGCGTAGTC   | 1193     | 9048     |
| TTCCGACGCTTCACAT   | 1193     | 9223     |
| GCTGTCTGTGATCGAC   | 1192     | 9397     |

---

### Step 2: Prepare Gene Expression Matrix

Your expression matrix should:

- Include **only the barcodes from Step 1** (in the same order)
- Have **columns as clone IDs** (e.g., `heavyclone0`, `heavyclone5`, etc.)
- Have **values** representing expression counts per barcode
- Create **two** expression matrices for both heavy chain and light chain data

**Example:**

| barcodes           | heavyclone0 | heavyclone5 | heavyclone7 |
|--------------------|-------------|-------------|-------------|
| AAACCTGAGCGTAGTC   | 0           | 0           | 0           |
| TTCCGACGCTTCACAT   | 0           | 0           | 0           |
| GCTGTCTGTGATCGAC   | 0           | 0           | 1           |

---

### Step 3: Combine into a Data Frame

Merge your spatial coordinates and gene expression matrix **by barcode** into a single data frame. You should create two dataframes for both heavy chain data and light chain data. This combined data will be used to create spatial **point pattern objects** (`ppp`) for each clone.

**Example:**

| barcodes           | imagerow | imagecol | heavyclone0 | heavyclone2 | heavyclone5 | heavyclone7 |
|--------------------|----------|----------|-------------|-------------|-------------|-------------|
| ATTCAGGATCGCCTCT   | 1193     | 9048     | 0           | 0           | 0           | 0           |
| GCCCATGGTGCAATG    | 1041     | 9135     | 0           | 0           | 0           | 0           |
| TTCCGACGCTTCACAT   | 1193     | 9223     | 0           | 0           | 0           | 0           |
| GCTGTCTGTGATCGAC   | 1192     | 9397     | 0           | 0           | 0           | 1           |
| AAGACTCACGCCCACCT  | 1192     | 9746     | 0           | 0           | 0           | 0           |


Once the dataframe is ready, you can use the provided scripts to:

1. Convert this into spatial point patterns
2. Compute distances between patterns
3. Run the REPAIR model
4. Apply the spatial pairing algorithm

---

## Step-by-Step Instructions

### Step 1: Convert DataFrame to Spatial Point Patterns

Process **heavy** and **light** chain expression matrices separately to create spatial point patterns for downstream analysis.


#### `clone_info_combined(df, img.scale = 1)`

**Input:**
- `df`: Expression matrix with:
  - Column 1: barcode  
  - Columns 2–3: spatial coordinates (`imagerow/imagecol` or `y/x`)  
  - Columns 4+: expression values for each clone  
- `img.scale`: Optional coordinate scaling factor (default = 1)

**Output:**
- A data frame with spatial info for each clone:  
  `x`, `y`, `n`, `clone_id`, `clone_id_rank`


#### `create_ppp_from_clone_info(clone_df)`

**Input:**
- `clone_df`: Output from `clone_info_combined()`

**Output:**
- A `ppp` object (spatial point pattern) with clone metadata as marks

---

### Step 2: Compute Distances Between Point Patterns

After generating spatial point patterns for light and heavy chains (Step 1), the next step is to compute a distance matrix that captures the spatial proximity between each pair of light and heavy clones.

This step uses spatial point pattern matching to evaluate how closely two patterns (a light clone and a heavy clone) co-localize across the tissue.


#### `spatial_distance_matrix(L.id, H.id, ppp_L, ppp_H, cutoff = 1e6)`

**Input:**
- `L.id`: Vector of light chain clone IDs  
- `H.id`: Vector of heavy chain clone IDs  
- `ppp_L`: Point pattern object for light clones  
- `ppp_H`: Point pattern object for heavy clones  
- `cutoff`: Maximum distance to consider for matching (default: `1e6`)

**Output:**
- A numeric matrix where:
  - Rows = heavy clones  
  - Columns = light clones  
  - Each value = distance between the corresponding point patterns


#### `transD(dist_matrix)`

**Input:**
- `dist_matrix`: Distance matrix from `spatial_distance_matrix()`

**Output:**
- A transformed matrix where:
  - Each row is normalized to sum to 1  
  - Larger distances are converted into smaller weights via exponential decay (`exp(-distance)`)

This normalized matrix will later be combined with the REPAIR model output to guide spatial pairing decisions.

---

### Step 3: Run the REPAIR Model

In this step, we use the [REPAIR model](https://github.com/almaan/star-repair) to infer pairing probabilities between heavy and light chain clones based on their expression profiles.


#### Prepare Input for REPAIR

REPAIR requires a **combined expression matrix** as input, where:
- **Rows** = heavy chain clones  
- **Columns** = light chain clones  
- **Values** = expression scores or estimated counts

You can create this by merging your heavy and light expression matrices into one combined file (e.g., `.tsv` format).


#### Run REPAIR from the Terminal

Use the following command format to run REPAIR:

```bash
repair analyze -i INPUT_FILE -o OUTDIR -ap A_PATTERN -bp B_PATTERN -x 1 -b 100 -nb 1

---

## Solution Output: Chain Pairing Results

After completing the data preparation and running the pairing algorithm, users can generate the **final pairing solution** matrix like the example shown below.

Each row in the output corresponds to a **heavy chain**, and each column corresponds to the **omega value** (the weight between spatial distance and expression similarity):

| heavy_ids | w=0 | w=0.1 | w=0.2 | ... | w=1 |
|-----------|-----|-------|-------|-----|-----|
| 1         | 0   | 0     | 0     | ... | 0   |
| 6         | 2   | 2     | 2     | ... | 2   |
| 8         | 10  | 10    | 10    | ... | 3   |
| ...       | ... | ...   | ...   | ... | ... |

**How to interpret this table:**
- The first column `heavy_ids` lists the IDs of heavy chains.
- Each remaining column (e.g., `w=0`, `w=0.1`, ..., `w=1`) corresponds to a **pairing solution** for a given value of ω (omega), the tuning parameter that balances spatial distance and expression-based similarity.
- The values in the table indicate which **light chain ID** each heavy chain is paired with under that omega setting.

**Why this structure?**
- In most datasets, there are **fewer heavy chains** than light chains. Therefore, we treat heavy chains as the row index.
- Researchers can inspect how pairings change with different ω values and select a pairing strategy based on spatial vs. expression-based priorities.

You can run the pairing code (see `/scripts`) to generate this output automatically from your point patterns and REPAIR mapping matrix.




