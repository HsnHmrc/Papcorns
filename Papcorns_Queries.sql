--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--For Task 1
--------------------------------------------------------------------------------------------

SELECT 
    u.country, 
    ROUND(SUM(e.amount_usd), 2) AS total_revenue
FROM user_events e
JOIN users u ON e.user_id = u.id
WHERE e.event_name IN ('subscription_started', 'subscription_renewed')
GROUP BY u.country;

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--For Task 2
--------------------------------------------------------------------------------------------

SELECT COUNT(*) AS total_trials
FROM user_events
JOIN users ON user_events.user_id = users.id
WHERE event_name = 'trial_started' 
AND attribution_source = 'instagram';

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--For Task 3
--------------------------------------------------------------------------------------------
--Adding Column
ALTER TABLE users ADD COLUMN acquisition_channel TEXT;

--Insert Data to New Column
UPDATE users
SET acquisition_channel = 
    CASE 
        WHEN attribution_source IN ('instagram', 'tiktok') THEN 'Paid'
        ELSE 'Organic'
    END;

--Check
select acquisition_channel from users;

--For Task 3
SELECT acquisition_channel, COUNT(id) AS user_count
FROM users
GROUP BY acquisition_channel;

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--For Task 4
--------------------------------------------------------------------------------------------
--a

WITH trial_users AS (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE event_name = 'trial_started'
),
first_subscriptions AS (
    SELECT user_id, MIN(created_at) AS first_subscription_date
    FROM user_events
    WHERE event_name = 'subscription_started'
    GROUP BY user_id
)
SELECT 
    COUNT(DISTINCT f.user_id) AS converted_users,
    COUNT(DISTINCT t.user_id) AS total_trials
FROM trial_users t
LEFT JOIN first_subscriptions f ON t.user_id = f.user_id;

--b

WITH trial_users AS (
    SELECT DISTINCT u.id AS user_id, u.attribution_source
    FROM user_events e
    JOIN users u ON e.user_id = u.id
    WHERE e.event_name = 'trial_started'
),
first_subscriptions AS (
    SELECT user_id, MIN(created_at) AS first_subscription_date
    FROM user_events
    WHERE event_name = 'subscription_started'
    GROUP BY user_id
)
SELECT 
    t.attribution_source,
    COUNT(DISTINCT f.user_id) AS converted_users,
    COUNT(DISTINCT t.user_id) AS total_trials
FROM trial_users t
LEFT JOIN first_subscriptions f ON t.user_id = f.user_id
GROUP BY t.attribution_source;

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--For Task 5
--------------------------------------------------------------------------------------------

WITH subscription_data AS (
    SELECT 
        e.user_id,
        u.country,
        e.created_at AS subscription_start,
        LEAD(e.created_at) OVER (PARTITION BY e.user_id ORDER BY e.created_at) AS subscription_end
    FROM user_events e
    JOIN users u ON e.user_id = u.id
    WHERE e.event_name IN ('subscription_started', 'subscription_cancelled')
)
SELECT 
    country,
    user_id,
    (JULIANDAY(subscription_end) - JULIANDAY(subscription_start)) / 30.0 AS subscription_duration_months
FROM subscription_data
WHERE subscription_end IS NOT NULL;

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--For Task 6
--------------------------------------------------------------------------------------------

SELECT u.country, 
       (SUM(e.amount_usd) * 1.0 / COUNT(DISTINCT u.id)) AS avg_ltv
FROM user_events e
JOIN users u ON e.user_id = u.id
WHERE e.event_name IN ('subscription_started', 'subscription_renewed')
GROUP BY u.country;	
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--For Bonus Tasks
--------------------------------------------------------------------------------------------
--RFM Analysis

WITH max_transaction_date AS (
    SELECT MAX(created_at) AS max_date FROM user_events
),
user_transactions AS (
    SELECT 
        e.user_id,
        MAX(e.created_at) AS last_purchase_date,  -- En son işlem tarihi
        COUNT(e.id) AS frequency,                -- İşlem sayısı
        SUM(e.amount_usd) AS monetary            -- Toplam harcama
    FROM user_events e
    WHERE e.user_id IN (1001, 1002)  -- Sadece Bruce Wayne ve Clark Kent
    GROUP BY e.user_id
)
SELECT 
    ut.user_id,
    u.name,
    (SELECT max_date FROM max_transaction_date) - DATE(ut.last_purchase_date) AS recency,  -- Recency hesaplama
    ut.frequency,
    ut.monetary
FROM user_transactions ut
JOIN users u ON u.id = ut.user_id;

--Check

SELECT 
    e.user_id, 
    u.name,
	u.country,
	u.attribution_source,
    e.event_name, 
    e.amount_usd, 
    e.created_at
FROM user_events e
JOIN users u ON e.user_id = u.id
WHERE e.user_id IN (1001, 1002)
ORDER BY e.user_id, e.created_at;