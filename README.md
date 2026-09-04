# Olist E-Commerce Customer Analytics — RFM Segmentation & BI Dashboard

An end-to-end customer analytics project on the Brazilian e-commerce platform Olist: exploratory data analysis in Python, RFM customer segmentation in SQL, and an interactive Power BI dashboard — built to answer a real business question: *who are Olist's most valuable customers, and why does retention keep failing?*

## Dataset

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — ~100k orders placed between 2016-2018 across multiple Brazilian marketplaces, covering orders, customers, products, payments, reviews, and sellers. Not included in this repo due to size — download directly from Kaggle to reproduce.

## Business Framing

Olist is a Brazilian e-commerce marketplace connecting small sellers to major retail channels. This project acts as a customer analytics consultant engagement: segment ~96,000 customers by value, identify what's driving dissatisfaction, and recommend where retention effort should go.

## Key Findings

- **Only ~3% of customers ever place a second order.** 96.9% are one-time buyers — meaning Frequency, RFM's usual strongest signal, barely differentiates customers here. The segmentation leans more heavily on Recency and Monetary as a result, and the low repeat rate is treated as a headline finding in its own right, not just an input to the model.
- **Late delivery is a massive driver of dissatisfaction.** Only 6.7% of orders arrive late, but those orders average a 2.27-star review vs. 4.29 for on-time orders — 53.7% of late orders get a 1-star review, compared to 6.6% for on-time orders.
- **Distance/logistics explains part of the regional satisfaction gap.** Same-state orders deliver in ~7.5 days on average vs. ~14.6 days for cross-state orders. Customers in São Paulo (SP) get a same-state order 76% of the time; customers in Rio de Janeiro (RJ) get one only 8% of the time — largely explaining why RJ customers report lower satisfaction (3.81 avg) than SP (4.13 avg).
- **Product-level dissatisfaction is only partly explained by delivery.** Checking the worst-rated products (min. 20 reviews) against their late-delivery rate shows a mixed picture: some are low-rated mainly due to shipping delays, others are poorly rated despite a 0% late-delivery rate — genuinely disliked products, not a logistics issue.

## Project Structure

```
├── notebooks/
│   └── olist_eda.ipynb          # Full exploratory data analysis
├── sql/
│   ├── rfm_segmentation.sql     # RFM calculation + segmentation (rfm_segments view)
│   └── segment_summary_by_state.sql  # Segment mix by state (rfm_segments_by_state view)
├── powerbi/
│   └── dashboard.pdf             # Static export of all 3 dashboard pages
└── README.md
```

## Methodology

**EDA (Python/pandas):** loaded and validated all 9 Olist source tables — checked for duplicates and nulls across every table (not just a convenient subset), and caught several data-quality issues before they could propagate downstream:
- `customer_id` is generated per-order, not per-customer — the real repeat-customer key is `customer_unique_id`. Using the wrong field would have made every customer look like a one-time buyer.
- Orders can have multiple payment rows (split across payment methods/installments) — `payment_value` must be summed per order before use.
- A small set of orders (8 of 96,478) are marked "delivered" with no delivery date recorded — caught by directly checking the row-level intersection of status and null dates, not just comparing aggregate totals.
- 610 products have no category listed, tied to genuinely incomplete seller listings — labeled `"unknown"` rather than dropped or imputed.

**RFM Segmentation (MySQL):** built via CTEs — Monetary uses `payment_value` (the actual amount paid, including any installment interest) rather than `price + freight_value`. Recency and Monetary are scored via `NTILE(5)` quintiles; Frequency uses a manual `CASE` mapping instead of `NTILE`, since ~97% of customers share the same Frequency value and `NTILE` produces inconsistent, arbitrary scores when the underlying data has that many ties. Segment labels are derived from all three scores, with explicit handling for every score combination (avoiding an oversized "catch-all" bucket).

**Dashboard (Power BI):** three pages — RFM Overview, Delivery & Logistics, and Category & Product — connected live to the MySQL database, with cross-page filtering via a shared segment slicer.

*Note: a small number of Page 2/3 calculations are computed at the order-item level (one row per item) rather than the order level used in the EDA notebook, so multi-item orders are counted once per item. This produces minor variance (a few percentage points) from the notebook's numbers on some metrics; the direction of every finding is consistent across both.*

## Dashboard

The live `.pbix` file exceeds GitHub's file size limit and is hosted externally:

**[Download the full interactive Power BI dashboard (Google Drive)](https://drive.google.com/file/d/147RkpVVmbg2__ZqvatgbQnnjvxKvtd9C/view?usp=drive_link)**

A static PDF export of all 3 pages is also included directly in this repo under `powerbi/` for quick viewing without downloading anything.

## Tools

Python (pandas, matplotlib, seaborn) · MySQL · Power BI · Jupyter

## Author

Mohit Goyal — [GitHub](https://github.com/Mohitgoyal-analyst)
