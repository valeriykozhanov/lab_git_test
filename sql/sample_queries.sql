
-- 3NF: отгруженные заявки за  30 дней
SELECT o.order_no, c.name AS counterparty, o.requested_date,
       SUM(oi.qty*oi.unit_price) AS total
FROM ops."order" o
JOIN ops.counterparty c USING (counterparty_id)
JOIN ops.order_item oi USING (order_id)
WHERE o.status = 'SHIPPED' AND o.created_at >= now() - INTERVAL '30 days'
GROUP BY o.order_no, c.name, o.requested_date
ORDER BY o.requested_date DESC;

-- 3NF: история статусов по заявке
SELECT o.order_no, h.status, h.changed_at, e.full_name
FROM ops.order_status_history h
JOIN ops."order" o ON o.order_id = h.order_id
LEFT JOIN ops.employee e ON e.employee_id = h.changed_by
WHERE o.order_no = 'ORD-0001'
ORDER BY h.changed_at;

