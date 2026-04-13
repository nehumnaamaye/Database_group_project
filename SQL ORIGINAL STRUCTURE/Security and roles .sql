-- ╔══════════════════════════════════════════════════════════════════╗
-- ║   AGRICULTURAL SERVICES DATABASE — NUCAFE                       ║
-- ║   PRESENTATION QUERIES — GROUPED BY USER ACCESS                 ║
-- ║   Ministry of Agriculture · Animal Industry · Uganda            ║
-- ╠══════════════════════════════════════════════════════════════════╣
-- ║   Connect as the correct user before each section               ║
-- ║   CLI: mysql -u <username> -p agri_services_db                  ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ════════════════════════════════════════════════════════════════
-- HOW TO SWITCH USERS IN THE CLI
-- ════════════════════════════════════════════════════════════════
--
--   Exit current session:   exit
--   Connect as admin:       mysql -u coffee_admin -p
--   Connect as worker:      mysql -u extension_worker -p
--   Connect as farmer:      mysql -u farmer -p
--
--   Passwords:
--     coffee_admin       →  admin123
--     extension_worker   →  extension_worker123
--     farmer             →  farmer123
--
--   Always run this after connecting:
USE agri_services_db;
--   Confirm who you are:
SELECT USER(), CURRENT_USER();


-- ════════════════════════════════════════════════════════════════
-- ██████████████████████████████████████████████████████████████
--   USER 1: coffee_admin
--   Password : admin123
--   Access   : ALL PRIVILEGES on agri_services_db
--   Role     : Database administrator / IT department
-- ██████████████████████████████████████████████████████████████
-- ════════════════════════════════════════════════════════════════
--
--   Connect: mysql -u coffee_admin -p
--            USE agri_services_db;
--
-- ════════════════════════════════════════════════════════════════


-- ── A1: Farmer leaderboard by total land ─────────────────────────
-- Full farmer table + production join — only admin can touch
-- raw farm and production_record tables directly like this.
SELECT
    fs.farmer_id,
    fs.full_name,
    fs.district,
    fs.farmer_category,
    fs.total_farms,
    fs.total_land_acres,
    CASE fs.cooperative_member
        WHEN 1 THEN 'Yes' ELSE 'No'
    END                                     AS cooperative_member,
    fn_revenue_estimate(
        COALESCE(SUM(pr.yield_kg), 0), 3500
    )                                       AS lifetime_revenue_ugx
FROM vw_farmer_summary fs
LEFT JOIN farm fm
       ON fm.farmer_id = fs.farmer_id
LEFT JOIN production_record pr
       ON pr.farm_id = fm.farm_id
GROUP BY
    fs.farmer_id, fs.full_name, fs.district,
    fs.farmer_category, fs.total_farms,
    fs.total_land_acres, fs.cooperative_member
ORDER BY fs.total_land_acres DESC;


-- ── A2: Season-on-season yield comparison ────────────────────────
-- Directly queries production_record — admin only.
SELECT
    pr.year,
    p.full_name                             AS farmer_name,
    fm.district,
    pr.quality_grade,
    SUM(CASE WHEN pr.season = 'Long'
             THEN pr.yield_kg ELSE 0 END)   AS long_season_kg,
    SUM(CASE WHEN pr.season = 'Short'
             THEN pr.yield_kg ELSE 0 END)   AS short_season_kg,
    SUM(pr.yield_kg)                        AS total_kg,
    fn_revenue_estimate(
        SUM(pr.yield_kg), 3500
    )                                       AS revenue_ugx
FROM production_record pr
JOIN  farm   fm ON fm.farm_id    = pr.farm_id
JOIN  farmer f  ON f.farmer_id   = fm.farmer_id
JOIN  person p  ON p.national_id = f.national_id
GROUP BY
    pr.year, f.farmer_id, p.full_name,
    fm.district, pr.quality_grade
ORDER BY pr.year DESC, total_kg DESC;


-- ── A3: District revenue leaderboard ─────────────────────────────
-- Multi-table aggregation across farm + production_record.
-- Admin only — both tables are restricted for lower roles.
SELECT
    fm.district,
    COUNT(DISTINCT f.farmer_id)             AS farmers,
    COUNT(DISTINCT fm.farm_id)              AS farms,
    ROUND(SUM(fm.land_size_acres), 2)       AS total_acres,
    ROUND(COALESCE(SUM(pr.yield_kg), 0), 2) AS total_yield_kg,
    fn_revenue_estimate(
        COALESCE(SUM(pr.yield_kg), 0), 3500
    )                                       AS estimated_revenue_ugx,
    ROUND(
        COALESCE(SUM(pr.yield_kg), 0) /
        NULLIF(COUNT(DISTINCT fm.farm_id), 0)
    , 2)                                    AS avg_yield_per_farm_kg
FROM farm fm
JOIN  farmer f ON f.farmer_id = fm.farmer_id
LEFT JOIN production_record pr ON pr.farm_id = fm.farm_id
GROUP BY fm.district
ORDER BY estimated_revenue_ugx DESC;


-- ── A4: Quality grade breakdown ──────────────────────────────────
-- Reads raw production_record — admin only.
SELECT
    pr.quality_grade,
    COUNT(*)                                AS record_count,
    ROUND(SUM(pr.yield_kg), 2)              AS total_yield_kg,
    ROUND(AVG(pr.yield_kg), 2)              AS avg_yield_kg,
    fn_revenue_estimate(
        SUM(pr.yield_kg), 3500
    )                                       AS revenue_ugx,
    CONCAT(
        ROUND(
            100.0 * SUM(pr.yield_kg) /
            (SELECT SUM(yield_kg) FROM production_record)
        , 1), '%'
    )                                       AS pct_of_total_yield
FROM production_record pr
GROUP BY pr.quality_grade
ORDER BY FIELD(pr.quality_grade, 'A', 'B', 'C', 'Ungraded');


-- ── A5: Full audit trail — all tables ────────────────────────────
-- audit_log is only accessible by coffee_admin.
-- Shows every sensitive change ever made to the database.
SELECT
    al.log_id,
    al.log_timestamp,
    al.table_name,
    al.operation,
    al.record_id,
    al.changed_by,
    al.old_values,
    al.new_values
FROM audit_log al
ORDER BY al.log_timestamp DESC
LIMIT 30;


-- ── A6: Stock audit trail — quantity changes only ────────────────
-- Narrows audit_log to resource quantity movements.
-- Demonstrates the trg_audit_resource_update trigger output.
SELECT
    al.log_id,
    al.log_timestamp,
    al.record_id                            AS resource_id,
    al.changed_by,
    JSON_UNQUOTE(
        JSON_EXTRACT(al.old_values, '$.qty')
    )                                       AS qty_before,
    JSON_UNQUOTE(
        JSON_EXTRACT(al.new_values, '$.qty')
    )                                       AS qty_after,
    JSON_UNQUOTE(
        JSON_EXTRACT(al.new_values, '$.batch_no')
    )                                       AS batch_no
FROM audit_log al
WHERE al.table_name = 'resource'
ORDER BY al.log_timestamp DESC
LIMIT 20;


-- ── A7: Ministry executive dashboard ─────────────────────────────
-- Single-row KPI summary. Only coffee_admin can see
-- vw_ministry_dashboard alongside raw programme_enrolment.
SELECT
    md.total_farmers,
    md.total_farms,
    md.smallholder_count,
    md.commercial_count,
    md.total_workers,
    md.interactions_last_30_days,
    md.total_yield_current_year_kg,
    fn_revenue_estimate(
        md.total_yield_current_year_kg, 3500
    )                                       AS projected_revenue_ugx,
    md.open_complaints,
    md.total_stock_units,
    (SELECT COUNT(*)
       FROM programme_enrolment
      WHERE completion_status = 'Completed') AS training_completions
FROM vw_ministry_dashboard md;


-- ── A8: Backup schedule configuration ────────────────────────────
-- Reads backup_config — admin only.
SELECT backup_type, frequency,
       retention_days, storage_path, notes
  FROM backup_config;

-- Print terminal backup/restore commands:
CALL sp_backup_reference();


-- ── A9: User & privilege matrix ──────────────────────────────────
-- Shows all three application users and their account status.
SELECT user, host, password_expired, account_locked
  FROM mysql.user
 WHERE user IN ('coffee_admin','extension_worker','farmer')
 ORDER BY user;


-- ── A10: Register a new farmer (stored procedure) ─────────────────
-- Atomic insert: person + farmer + smallholder subtype.
-- Roll back safely — re-run only once per demo.
CALL sp_register_farmer(
    'CM999001Z',
    'Nakato Aisha',
    '1993-07-14',
    'Female',
    '0772999001',
    'nakato@gmail.com',
    'Mukono',
    'Kiwanga',
    0,
    'Smallholder',
    'High',
    NULL
);

-- Verify:
SELECT farmer_id, full_name, district,
       farmer_category, registration_date
  FROM vw_farmer_summary
 WHERE full_name = 'Nakato Aisha';


-- ── A11: District report procedure ───────────────────────────────
CALL sp_district_report('Mukono', 2023);


-- ── A12: Distribute a resource + verify stock deduction ──────────
-- Shows trg_auto_deduct_stock trigger firing live.
SELECT resource_id, batch_no, quantity_available
  FROM resource WHERE resource_id = 3;

CALL sp_distribute_resource(
    3, 3, 50, 'Jinja',
    'Jinja Sub-county Office', 'Nabirye Grace'
);

-- Stock should be reduced by 50:
SELECT resource_id, batch_no, quantity_available
  FROM resource WHERE resource_id = 3;


-- ════════════════════════════════════════════════════════════════
-- ██████████████████████████████████████████████████████████████
--   USER 2: extension_worker
--   Password : extension_worker123
--   Access   : SELECT on operational tables + secure views
--              INSERT / UPDATE on farm, production_record,
--              interaction, advisory_session, distribution_event,
--              complaint_feedback, programme_enrolment,
--              coop_membership
--              EXECUTE on all stored procedures and functions
--   Role     : Field extension officers / district coordinators
-- ██████████████████████████████████████████████████████████████
-- ════════════════════════════════════════════════════════════════
--
--   Connect: mysql -u extension_worker -p
--            USE agri_services_db;
--
-- ════════════════════════════════════════════════════════════════


-- ── E1: Farmer list — no national ID visible ──────────────────────
-- Uses vw_secure_farmer — personal data is shown but NIN is hidden.
-- national_id column does not exist in this view by design.
SELECT
    farmer_id,
    full_name,
    phone_number,
    district,
    village_lc1,
    gender,
    age,
    farmer_category,
    cooperative_member,
    total_farms,
    total_acres
FROM vw_secure_farmer
ORDER BY district, full_name;


-- ── E2: Farm register — no farmer NIN visible ─────────────────────
-- Uses vw_secure_farm — GPS, soil, water, altitude all visible
-- but farmer's national_id is never exposed.
SELECT
    farm_id,
    farmer_name,
    farmer_contact,
    district,
    village,
    land_size_acres,
    soil_type,
    water_source,
    altitude_m,
    farm_variety_type,
    total_yield_kg
FROM vw_secure_farm
ORDER BY district, land_size_acres DESC;


-- ── E3: Stock availability — no unit cost visible ─────────────────
-- Uses vw_secure_stock — extension workers can see quantities
-- but the unit_cost_ugx column is hidden by the security view.
SELECT
    resource_id,
    batch_no,
    date_received,
    quantity_available,
    stock_status,
    supplier_name,
    supplier_location,
    resource_description
FROM vw_secure_stock
ORDER BY
    FIELD(stock_status,
          'Out of Stock','Low Stock',
          'Adequate','Well Stocked');


-- ── E4: Ministry dashboard summary ───────────────────────────────
-- vw_ministry_dashboard is granted to extension_worker.
-- Aggregate numbers only — no personal data.
SELECT *
  FROM vw_ministry_dashboard;


-- ── E5: Farmers overdue for a visit ──────────────────────────────
-- Uses only farmer, person, interaction — all SELECT-granted.
-- fn_farmer_type function is also EXECUTE-granted.
SELECT
    p.full_name                             AS farmer_name,
    p.phone_number,
    p.district,
    fn_farmer_type(f.farmer_id)             AS category,
    MAX(i.activity_date)                    AS last_interaction,
    DATEDIFF(CURDATE(),
             MAX(i.activity_date))          AS days_since_contact
FROM farmer f
JOIN  person p ON p.national_id = f.national_id
LEFT JOIN interaction i
       ON i.farmer_id       = f.farmer_id
      AND i.activity_status = 'Completed'
GROUP BY
    f.farmer_id, p.full_name,
    p.phone_number, p.district
HAVING days_since_contact > 60
    OR last_interaction IS NULL
ORDER BY days_since_contact DESC;


-- ── E6: Distribution trail ────────────────────────────────────────
-- Uses distribution_event, interaction, resource — all granted.
-- fn_stock_status function is EXECUTE-granted.
SELECT
    r.batch_no,
    CASE
        WHEN se.seedling_id IS NOT NULL THEN 'Seedling'
        WHEN ip.input_id    IS NOT NULL THEN 'Input'
        ELSE 'Unclassified'
    END                                     AS resource_type,
    p.full_name                             AS farmer_name,
    de.quantity_given,
    de.distribution_point,
    i.activity_date,
    CASE de.acknowledgement_signed
        WHEN 1 THEN 'Signed' ELSE 'Unsigned'
    END                                     AS acknowledgement,
    fn_stock_status(r.quantity_available)   AS stock_remaining_status
FROM distribution_event de
JOIN  interaction   i  ON i.activity_id  = de.activity_id
JOIN  farmer        f  ON f.farmer_id    = i.farmer_id
JOIN  person        p  ON p.national_id  = f.national_id
JOIN  resource      r  ON r.resource_id  = de.resource_id
LEFT JOIN seedling se  ON se.resource_id = r.resource_id
LEFT JOIN input    ip  ON ip.resource_id = r.resource_id
ORDER BY i.activity_date DESC;


-- ── E7: Log a new advisory session (stored procedure) ────────────
-- EXECUTE on sp_log_advisory is granted.
-- trg_complete_interaction_advisory fires automatically.
CALL sp_log_advisory(
    1,
    1,
    'Mukono',
    'Advised on timely weeding and mulching before the long season.',
    1,
    DATE_ADD(CURDATE(), INTERVAL 30 DAY),
    'Individual'
);

-- Verify the interaction was auto-marked Completed by trigger:
SELECT activity_id, activity_status, activity_date
  FROM interaction
 ORDER BY activity_id DESC
 LIMIT 1;


-- ── E8: Distribute a resource (stored procedure) ──────────────────
-- EXECUTE on sp_distribute_resource is granted.
-- trg_auto_deduct_stock and trg_prevent_overstock both fire.
SELECT resource_id, batch_no, quantity_available
  FROM resource WHERE resource_id = 1;

CALL sp_distribute_resource(
    1, 1, 10,
    'Mukono', 'Namanve Sub-county Office', 'Ssekandi Robert'
);

SELECT resource_id, batch_no, quantity_available
  FROM resource WHERE resource_id = 1;


-- ── E9: Register a new farm (stored procedure) ────────────────────
-- EXECUTE on sp_register_farm is granted.
-- Inserts farm + robusta_farm subtype atomically.
CALL sp_register_farm(
    1,              -- farmer_id
    0.3601,         -- gps_latitude
    32.7700,        -- gps_longitude
    2.0,            -- land_size_acres
    'Loam',         -- soil_type
    'Borehole',     -- water_source
    1050,           -- altitude_m
    'Mukono',       -- district
    'Namanve',      -- village
    'Robusta',      -- variety_type
    NULL,           -- robusta_pct (Mixed only)
    NULL            -- arabica_pct (Mixed only)
);

-- ── E10: Record a production harvest (stored procedure) ───────────
-- EXECUTE on sp_record_production is granted.
-- trg_block_future_harvest fires automatically if date is future.
CALL sp_record_production(
    1,              -- farm_id
    'Short',        -- season
    2024,           -- year
    '2024-04-01',   -- harvest_date
    320.00,         -- yield_kg
    'B',            -- quality_grade
    NULL            -- pest_issues
);


-- ── E11: Resolve a complaint (stored procedure) ───────────────────
-- EXECUTE on sp_resolve_complaint is granted.
-- trg_auto_resolve_date fires and sets resolved_date automatically.
SELECT complaint_id, resolution_status, resolved_date
  FROM complaint_feedback
 WHERE resolution_status IN ('Open','In Progress');

CALL sp_resolve_complaint(2, 'Resolved');

-- Verify resolved_date was auto-set by trigger:
SELECT complaint_id, resolution_status, resolved_date
  FROM complaint_feedback WHERE complaint_id = 2;


-- ════════════════════════════════════════════════════════════════
-- ██████████████████████████████████████████████████████████████
--   USER 3: farmer
--   Password : farmer123
--   Access   : SELECT on reporting views only
--              EXECUTE on fn_stock_status, fn_revenue_estimate
--              Cannot access any raw table
--              Cannot INSERT, UPDATE, or DELETE anything
--   Role     : Ministry auditors / UCDA / researchers
-- ██████████████████████████████████████████████████████████████
-- ════════════════════════════════════════════════════════════════
--
--   Connect: mysql -u farmer -p
--            USE agri_services_db;
--
-- ════════════════════════════════════════════════════════════════


-- ── F1: Farmer summary report ─────────────────────────────────────
-- vw_farmer_summary is SELECT-granted to farmer user.
-- No personal NIN visible — names and totals only.
SELECT
    farmer_id,
    full_name,
    district,
    farmer_category,
    total_farms,
    total_land_acres,
    cooperative_member,
    registration_date
FROM vw_farmer_summary
ORDER BY total_land_acres DESC;


-- ── F2: Production revenue report ────────────────────────────────
-- vw_production_revenue is SELECT-granted.
-- fn_revenue_estimate is EXECUTE-granted.
SELECT
    farmer_name,
    district,
    season,
    year,
    yield_kg,
    quality_grade,
    revenue_estimate_ugx
FROM vw_production_revenue
ORDER BY year DESC, yield_kg DESC;


-- ── F3: Cooperative membership summary ───────────────────────────
-- vw_cooperative_summary is SELECT-granted.
-- Aggregate numbers only — no member personal data.
SELECT
    coop_name,
    district,
    chairperson,
    date_established,
    member_count
FROM vw_cooperative_summary
ORDER BY member_count DESC;


-- ── F4: Resource value report ─────────────────────────────────────
-- vw_resource_value is SELECT-granted.
-- Includes unit_cost_ugx and total_value_ugx — full financial view.
-- fn_stock_status is EXECUTE-granted.
SELECT
    batch_no,
    resource_type,
    supplier_name,
    quantity_available,
    fn_stock_status(quantity_available)     AS stock_status,
    unit_cost_ugx,
    total_value_ugx
FROM vw_resource_value
ORDER BY total_value_ugx DESC;


-- ── F5: Full interaction log ──────────────────────────────────────
-- vw_interaction_log is SELECT-granted.
-- Shows advisory sessions and distribution events in one view.
SELECT
    activity_id,
    activity_date,
    farmer_name,
    district,
    interaction_type,
    worker_name,
    quantity_given,
    activity_status
FROM vw_interaction_log
ORDER BY activity_date DESC;


-- ── F6: Extension worker profiles ────────────────────────────────
-- vw_worker_profile is SELECT-granted.
-- Derived years_of_service visible — national_id is not.
SELECT
    staff_id,
    full_name,
    worker_role,
    expertise_area,
    assigned_region,
    years_of_service
FROM vw_worker_profile
ORDER BY years_of_service DESC;


-- ── F7: Revenue estimate function test ───────────────────────────
-- fn_revenue_estimate and fn_stock_status are the only two
-- functions EXECUTE-granted to the farmer user.
-- Useful to demonstrate the privilege boundary clearly.
SELECT
    fn_revenue_estimate(1000, 3500)         AS rev_1000kg_ugx,
    fn_revenue_estimate(5000, 3500)         AS rev_5000kg_ugx,
    fn_stock_status(0)                      AS status_0,
    fn_stock_status(50)                     AS status_50,
    fn_stock_status(500)                    AS status_500,
    fn_stock_status(5000)                   AS status_5000;


-- ── F8: EXPECTED FAIL — raw table access blocked ──────────────────
-- Run this to demonstrate the privilege boundary to an audience.
-- farmer user cannot SELECT from raw tables.
SELECT * FROM farmer;
-- Expected error:
-- ERROR 1142 (42000): SELECT command denied to user
--                     'farmer'@'localhost' for table 'farmer'


-- ── F9: EXPECTED FAIL — INSERT blocked ───────────────────────────
-- farmer user has no INSERT privilege anywhere.
INSERT INTO complaint_feedback
    (farmer_id, date_raised, category, description)
VALUES (1, CURDATE(), 'General', 'Test complaint');
-- Expected error:
-- ERROR 1142 (42000): INSERT command denied to user
--                     'farmer'@'localhost' for table 'complaint_feedback'


-- ════════════════════════════════════════════════════════════════
-- END OF USER-ACCESS PRESENTATION QUERIES
-- ════════════════════════════════════════════════════════════════