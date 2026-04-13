USE agri_services_db;

-- ══════════════════════════════════════════════════════════════════
-- SECTION 1: USER ACCOUNTS (Updated)
-- ══════════════════════════════════════════════════════════════════

DROP USER IF EXISTS 'agri_admin'@'localhost';
DROP USER IF EXISTS 'agri_officer'@'localhost';
DROP USER IF EXISTS 'agri_readonly'@'localhost';
DROP USER IF EXISTS 'coffee_admin'@'localhost';
DROP USER IF EXISTS 'extension_worker'@'localhost';
DROP USER IF EXISTS 'farmer'@'localhost';

-- ── Create coffee_admin ───────────────────────────────────────────
CREATE USER 'coffee_admin'@'localhost'
    IDENTIFIED BY 'admin123'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5
    PASSWORD_LOCK_TIME 1;

-- ── Create extension_worker ───────────────────────────────────────
CREATE USER 'extension_worker'@'localhost'
    IDENTIFIED BY 'extension_worker123'
    PASSWORD EXPIRE INTERVAL 90 DAY
    FAILED_LOGIN_ATTEMPTS 5
    PASSWORD_LOCK_TIME 1;

-- ── Create farmer ─────────────────────────────────────────────────
CREATE USER 'farmer'@'localhost'
    IDENTIFIED BY 'farmer123'
    PASSWORD EXPIRE INTERVAL 180 DAY
    FAILED_LOGIN_ATTEMPTS 5
    PASSWORD_LOCK_TIME 1;


-- ══════════════════════════════════════════════════════════════════
-- SECTION 2: PRIVILEGE GRANTS (Updated)
-- ══════════════════════════════════════════════════════════════════

-- ── coffee_admin: full control ────────────────────────────────────
GRANT ALL PRIVILEGES
    ON agri_services_db.*
    TO 'coffee_admin'@'localhost'
    WITH GRANT OPTION;


-- ── extension_worker: read non-sensitive tables ───────────────────
GRANT SELECT ON agri_services_db.cooperative            TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.training_programme     TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.coffee_variety         TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.supplier               TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.resource               TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.seedling               TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.input                  TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.farm                   TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.farm_variety           TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.production_record      TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.interaction            TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.advisory_session       TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.distribution_event     TO 'extension_worker'@'localhost';
GRANT SELECT ON agri_services_db.complaint_feedback     TO 'extension_worker'@'localhost';

-- ── extension_worker: insert and update operational records ───────
GRANT INSERT, UPDATE ON agri_services_db.farm                TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.farm_variety        TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.production_record   TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.interaction         TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.advisory_session    TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.distribution_event  TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.complaint_feedback  TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.programme_enrolment TO 'extension_worker'@'localhost';
GRANT INSERT, UPDATE ON agri_services_db.coop_membership     TO 'extension_worker'@'localhost';

-- ── extension_worker: execute stored procedures and functions ─────
GRANT EXECUTE ON PROCEDURE agri_services_db.sp_register_farmer           TO 'extension_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agri_services_db.sp_distribute_resource       TO 'extension_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agri_services_db.sp_log_advisory              TO 'extension_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agri_services_db.sp_resolve_complaint         TO 'extension_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agri_services_db.sp_register_extension_worker TO 'extension_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agri_services_db.sp_register_farm             TO 'extension_worker'@'localhost';
GRANT EXECUTE ON PROCEDURE agri_services_db.sp_record_production         TO 'extension_worker'@'localhost';
GRANT EXECUTE ON FUNCTION  agri_services_db.fn_farmer_type               TO 'extension_worker'@'localhost';
GRANT EXECUTE ON FUNCTION  agri_services_db.fn_total_yield               TO 'extension_worker'@'localhost';
GRANT EXECUTE ON FUNCTION  agri_services_db.fn_stock_status              TO 'extension_worker'@'localhost';
GRANT EXECUTE ON FUNCTION  agri_services_db.fn_days_since_visit          TO 'extension_worker'@'localhost';


-- ── farmer: reporting views and aggregate functions only ──────────
GRANT SELECT ON agri_services_db.vw_farmer_summary      TO 'farmer'@'localhost';
GRANT SELECT ON agri_services_db.vw_resource_value      TO 'farmer'@'localhost';
GRANT SELECT ON agri_services_db.vw_cooperative_summary TO 'farmer'@'localhost';
GRANT SELECT ON agri_services_db.vw_production_revenue  TO 'farmer'@'localhost';
GRANT SELECT ON agri_services_db.vw_interaction_log     TO 'farmer'@'localhost';
GRANT SELECT ON agri_services_db.vw_worker_profile      TO 'farmer'@'localhost';
GRANT EXECUTE ON FUNCTION agri_services_db.fn_stock_status     TO 'farmer'@'localhost';
GRANT EXECUTE ON FUNCTION agri_services_db.fn_revenue_estimate TO 'farmer'@'localhost';

FLUSH PRIVILEGES;


-- ══════════════════════════════════════════════════════════════════
-- VERIFICATION: Confirm users and grants
-- ══════════════════════════════════════════════════════════════════

SELECT user, host, password_expired, account_locked
  FROM mysql.user
 WHERE user IN ('coffee_admin', 'extension_worker', 'farmer')
 ORDER BY user;

SHOW GRANTS FOR 'coffee_admin'@'localhost';
SHOW GRANTS FOR 'extension_worker'@'localhost';
SHOW GRANTS FOR 'farmer'@'localhost';