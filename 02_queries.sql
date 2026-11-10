SELECT COUNT(*) FROM clinics;                        -- 8
SELECT COUNT(*), SUM(no_show) FROM appointments;     -- 990, 218
INSERT INTO appointments VALUES ('A0001','P999','C01','2025-01-01','2025-01-05',30,'F',5.0,500,'App','Consultation','Yes',0,'Attended',4,0);     -- the line above
-- Duplicate insert error: Error Code: 1062. Duplicate entry 'A0001' for key 'appointments.PRIMARY'

-- ===== Task 2.2 =====
SELECT c.clinic_name,
       c.city,
       COUNT(*)        AS appointments,
       SUM(a.no_show)  AS no_shows,                                 
       ROUND(100.0 * SUM(a.no_show) / COUNT(*), 2) AS no_show_pct   
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id                                
GROUP BY c.clinic_name, c.city
HAVING COUNT(*) >= 95                                                 
ORDER BY no_show_pct DESC;         

-- ===== Task 2.3 =====
SELECT CASE WHEN lead_days <= 7 THEN '1-7'          
            WHEN lead_days <= 14 THEN '8-14'         
            WHEN lead_days <= 30 THEN '15-30'        
            ELSE '31+'                           
       END AS lead_band,
       COUNT(*) AS appointments,
       SUM(no_show) AS no_shows,
       ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_band                                     
ORDER BY MIN(lead_days);

-- ===== Task 2.4 =====
WITH monthly AS (
    SELECT SUBSTR(appt_date, 1, 7) AS month,                      -- BLANK 6
           COUNT(*) AS appointments,
           ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY month
)
SELECT month,
       appointments,
       no_show_pct,
       ROUND(no_show_pct - LAG(no_show_pct) OVER (ORDER BY month), 1) AS change_pp   -- BLANK 7
FROM monthly                                                           -- BLANK 8: query the CTE
ORDER BY month;

-- ===== Task 2.5 =====
WITH clinic_rates AS (
    SELECT c.clinic_name AS clinic,
           c.city,
           ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments a
    JOIN clinics c ON a.clinic_id = c.clinic_id
    GROUP BY c.clinic_name, c.city
)
SELECT clinic,
       city,
       no_show_pct,
       RANK() OVER (PARTITION BY city ORDER BY no_show_pct DESC) AS rank_in_city, 
       CASE WHEN no_show_pct > (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'above'
            WHEN no_show_pct < (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'below'  
            ELSE 'equal'                                                                           
       END AS vs_overall
FROM clinic_rates
ORDER BY city, rank_in_city; 
