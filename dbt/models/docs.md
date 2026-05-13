{% docs olist_order_status_definition %}
该字段定义了订单在 Olist 平台的生命周期状态：
- **delivered**: 订单已成功送达客户手中。这是计算 GMV 和物流时效的核心指标。
- **shipped/processing/invoiced**: 订单处理中，尚未完成交付。
- **canceled**: 订单已取消。在财务口径中，此类订单应被剔除。
- **unavailable**: 缺货或其他原因导致的不可用状态。
{% enddocs %}

{% docs olist_weight_class_definition %}
基于商品物理重量（克）的逻辑分类：
- **Light**: < 500g (适合普通快递)
- **Medium**: 500g - 2000g
- **Heavy**: > 2000g (可能涉及大件物流加价)
{% enddocs %}

{% docs olist_rfm_logic %}
客户价值分群逻辑：
- **Recency (R)**: 距离上次购买的天数。数值越小，活跃度越高。
- **Frequency (F)**: 累计购买次数。
- **Monetary (M)**: 累计购买总金额。
通过对 R/F/M 进行评分，将客户划分为“核心客户”、“重点挽留客户”等。
{% enddocs %}