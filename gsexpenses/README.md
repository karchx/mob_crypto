# GSEXPENSE

GSEXpense is a data lake and statistical analysis tool for personal finance, plus a browser extension for Mob Crypto that helps manage your portfolio data—powered by mathematics and statistics, not AI.

## ER base data lake
```
                  +----------------------+
                  |       dim_time       |
                  +----------------------+
                  | pk_date (int)        |
                  | day (date)           |
                  | year (int)           |
                  | month (int)          |
                  | day_of_week (int)    |
                  | fortnight (int)      |
                  +---------+------------+
                            |
                            | 1:N
                            v
+--------------------+    +----------------------+
|    dim_category    |    |  fact_transactions   |
+--------------------+    +----------------------+
| pk_category (int)  |    | pk_transaction (str) |
| name (str)         |--->| fk_date (int)        |
| type (str)         |1:N | fk_category (int)    |
| is_recurring (bool)|    | amount (decimal)     |
+--------------------+    | description (str)    |
                          | batch_cycle (str)    |
                          +----------------------+
```
