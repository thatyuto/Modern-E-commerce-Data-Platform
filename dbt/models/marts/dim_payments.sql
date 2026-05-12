with final as (
    select 
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,
        -- 按订单汇总总金额（窗口函数，不合并行）
        sum(payment_value) over (partition by order_id) as total_payment_value
    from {{ref('stg_payments')}}
)
select * from final