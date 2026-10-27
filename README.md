# procure-to-pay-sql-analysis
MySQL project simulating procure-to-pay data validation and supplier analysis on the Olist e-commerce dataset, using joins, CTEs and window functions.
# Procure-to-Pay Data Validation and Analysis (MySQL)

## Overview
This project uses the public Olist Brazilian E-Commerce dataset (Kaggle) to simulate a procurement data environment in MySQL. The e-commerce data is mapped onto a procure-to-pay model for learning purposes:

| Olist table | Treated as |
|---|---|
| sellers | Suppliers |
| orders | Purchase orders (POs) |
| order_items | PO line items |
| order_payments | Invoices and payments |

The project loads the raw data, runs SQL validation checks, and analyzes supplier spend and delivery performance.

## Tech
MySQL, SQL (joins, CTEs, window functions), Python (pandas) for loading CSV files

## Dataset
[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) on Kaggle. Tables used: sellers, orders, order_items, order_payments.

## Files
| File | Purpose |
|---|---|
| 01_create_tables.sql | Creates the database and four tables |
| 02_validation.sql | Data validation checks |
| 03_analysis.sql | Supplier analysis queries |

## Data loaded
| Table | Rows |
|---|---|
| sellers | 3,095 |
| orders | 99,441 |
| order_items | 112,650 |
| order_payments | 103,886 |

## Validation log
| # | Check | Result |
|---|---|---|
| 1 | Row counts per table | See table above |
| 2 | Duplicate line items (same order and item number) | 0 |
| 3 | Missing approval dates | 160 (146 explained by canceled/created status; 14 delivered orders flagged) |
| 3 | Missing delivery dates | 2,965 (2,957 explained by non-delivered status; 8 delivered orders flagged) |
| 4 | Orphan order items (no matching order) | 0 |
| 5 | Orders delivered before purchase date | 0 |
| 6 | Orders where payment total differs from item total by more than 1 | 249 (232 overpaid, 17 underpaid) |
| 7 | Delivered orders with missing timestamps | 22 (14 missing approval date, 8 missing delivery date) |

## Data quality findings
- Most missing timestamps are legitimate: orders that were canceled, shipped, unavailable or still processing have no delivery date (2,957 of 2,965 missing delivery dates; 146 of 160 missing approval dates).
- 22 orders marked "delivered" have inconsistent timestamps:
  - 14 have a delivery date but no approval date. All were delivered between 30 Jan and 9 Mar 2017, which suggests a data capture issue in that period.
  - 8 have an approval date but no delivery date.
- In a real project, these 22 records would be flagged to the source system owner for correction before migration.

## Payment reconciliation finding
- 249 orders (about 0.25% of 99,441) have a payment total that differs from the item total (price + freight) by more than 1.
- 232 of these (93%) are overpayments and 17 (7%) are underpayments.
- Mismatched orders averaged 6.3 payment installments, compared with 2.9 across all orders. This is consistent with installment charges or interest, though the dataset does not include interest rates, so the cause cannot be confirmed.

## Key insights
1. Spend is widely distributed across 3,095 suppliers (total item spend 13,591,643.70). The top supplier (4869f7a5...) accounts for 229,472.63 (about 1.7%), and the top 3 suppliers together account for about 4.8%, so no single supplier dominates.
2. Overall, 91.9% of delivered orders arrived on or before the estimated date. Among suppliers with at least 30 delivered orders, the three weakest were well below that: 66.0% (ede0c036..., 43 orders), 67.9% (54965bbe..., 73 orders) and 68.4% (ad781527..., 38 orders). These would be the first candidates for a performance review.
3. Spend peaked in November 2017 at 1,010,271.37.

## How to run
1. Download the four CSV files from Kaggle.
2. Run 01_create_tables.sql in MySQL.
3. Load each CSV into its matching table (I used Python with pandas).
4. Run 02_validation.sql, then 03_analysis.sql.
## Assumptions and limitations
- This is an e-commerce dataset mapped onto a procurement model, not real procurement data.
- Missing delivery dates are expected for orders that were canceled or not yet delivered.
