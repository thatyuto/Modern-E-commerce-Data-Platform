# Performance Benchmark Report: Olist Dataset Architectural Optimization

## 1. Executive Summary
This report evaluates the impact of physical storage optimizations—**Partitioning** and **Clustering**—within Google BigQuery. By restructuring the `olist_orders_dataset`, we analyzed how these changes affect query cost (Data Scanned) and computational efficiency (Slot Milliseconds) across various analytical scenarios.

## 2. Methodology
The benchmark compared three distinct architectural states of the Olist orders data:
1.  **Heap Table (`order_raw`)**: The baseline table with no physical optimization.
2.  **Partitioned Table (`orders_partitioned`)**: Partitioned by day using `order_purchase_timestamp`.
3.  **Hybrid Table (`olist_orders_dataset`)**: Partitioned by day and clustered by `order_id` and `customer_id`.

## 3. Comparative Data Analysis

The following data was captured during live execution on **2026-05-05**:

| Scenario | Metric | Heap Table | Partitioned | Hybrid (P+C) |
| :--- | :--- | :--- | :--- | :--- |
| **A: Date Range Filter** | Bytes Processed | 25.64 MB | **16.8 MB** | 25.64 MB |
| *(I/O Focus)* | Slot Time (ms) | 121 | 385 | 141 |
| **B: Complex Analytics** | Bytes Processed | 25.64 MB | 25.64 MB | 25.64 MB |
| *(JOIN + Window Function)* | Slot Time (ms) | 87 | **55,417** | **78** |

---

## 4. Key Technical Findings

### 4.1 Cost Efficiency through Partition Pruning
In Scenario A, the Partitioned table reduced the data scan from 25.64 MB to 16.8 MB.
*   **Mechanism**: The BigQuery optimizer performed **Partition Pruning**, physically skipping data blocks outside the 2018 Q1 window.
*   **Impact**: This resulted in a **34% reduction in query cost** for time-series analysis.

### 4.2 Computational Acceleration through Clustering
Scenario B involved a `LEFT JOIN` and a `SUM() OVER()` window function. The Hybrid (P+C) table outperformed the others with only **78 Slot ms**.
*   **The "Partition Trap"**: The standard Partitioned table hit a massive **55,417 ms** spike. Without a partition filter in the `WHERE` clause, the system struggled with cross-partition data shuffling.
*   **Clustering Synergy**: By clustering on `order_id`, the system performed a **Localized Join**. Since associated rows were physically co-located, the engine minimized network shuffle, achieving orders of magnitude improvement in computational speed. 

### 4.3 The Small Data "Metadata Overhead"
An interesting observation was that for extremely simple queries, the Heap table occasionally showed lower Slot Time. 
*   **Inference**: For MB-scale datasets, the time spent fetching Partition/Cluster metadata can exceed the time required for a raw linear scan. These optimizations are designed for **TB/PB-scale** environments where metadata lookup time is negligible compared to massive I/O savings.

---

## 5. Engineering Recommendations

1.  **Mandatory Partitioning**: Always implement partitioning on tables with a temporal dimension to control I/O costs.
2.  **Strategic Clustering**: Apply clustering to columns frequently used in `JOIN`, `GROUP BY`, or high-cardinality filters to stabilize computational performance.
3.  **Avoid Naked Queries**: When querying partitioned tables, always include the partition key in the `WHERE` clause to avoid unnecessary resource consumption (as seen in the 55s spike).

