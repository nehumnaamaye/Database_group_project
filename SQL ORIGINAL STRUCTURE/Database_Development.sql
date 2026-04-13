-- ╔══════════════════════════════════════════════════════════════════╗
-- ║   AGRICULTURAL SERVICES DATABASE                                 ║
-- ║   Ministry of Agriculture · Animal Industry · Uganda (NUCAFE)    ║
-- ╠══════════════════════════════════════════════════════════════════╣
-- ║   MILESTONE THREE: Database Development                          ║
-- ║   Structure & Data Validation                                    ║
-- ╠══════════════════════════════════════════════════════════════════╣
-- ║   Tool      : MySQL 8.0 + VS Code                                ║
-- ║   Group     : Group 4                                            ║
-- ║   Course    : Database Systems                                   ║
-- ║   University: Uganda Christian University, Mukono                ║
-- ╚══════════════════════════════════════════════════════════════════╝
--
-- ┌─────────────────────────────────────────────────────────────────┐
-- │ CONTENTS                                                        │
-- │  SECTION 1  ─ Database creation                                 │
-- │  SECTION 2  ─ Table definitions / DDL                           │
-- │  SECTION 3  ─ Indexes                                           │
-- │  SECTION 4  ─ Views / derived attributes                        │
-- │  SECTION 5  ─ Stored functions                                  │
-- │  SECTION 6  ─ Stored procedures                                 │
-- │  SECTION 7  ─ Disjoint constraint triggers                      │
-- │  SECTION 8  ─ Sample data (DML)                                 │
-- │  SECTION 9  ─ Constraint validation tests                       │
-- │  SECTION 10 ─ Business demonstration queries                    │
-- └─────────────────────────────────────────────────────────────────┘


-- ══════════════════════════════════════════════════════════════════
-- SECTION 1: DATABASE CREATION
-- ══════════════════════════════════════════════════════════════════

DROP DATABASE IF EXISTS agri_services_db;

CREATE DATABASE agri_services_db
    CHARACTER SET utf8mb4
    COLLATE     utf8mb4_unicode_ci;

USE agri_services_db;


-- ══════════════════════════════════════════════════════════════════
-- SECTION 2: TABLE DEFINITIONS  (DDL)
--
-- Table creation order follows FK dependencies.
-- Every table is commented to explain its EERD role.
-- Constraints are named so error messages are readable.
--
-- EERD ENTITY MAP:
--   person            → Supertype  (Hierarchy 1)
--   farmer            → Subtype L1 of person
--   extension_worker  → Subtype L1 of person  (overlapping)
--   field_officer     → Subtype L2 of extension_worker (disjoint)
--   trainer           → Subtype L2 of extension_worker (disjoint)
--   cooperative       → Standalone entity
--   coop_membership   → Associative (farmer ↔ cooperative  M:N)
--   farm              → Supertype  (Hierarchy 2)
--   coffee_variety    → Standalone entity
--   farm_variety      → Associative (farm ↔ coffee_variety M:N)
--   production_record → Weak entity → farm
--   supplier          → Standalone entity
--   resource          → Supertype  (Hierarchy 3)
--   seedling          → Subtype of resource (disjoint)
--   input             → Subtype of resource (disjoint)
--   training_programme→ Standalone entity
--   programme_enrolment→ Associative (farmer ↔ training M:N)
--   interaction       → Supertype  (Hierarchy 4)
--   advisory_session  → Subtype of interaction (disjoint)
--   distribution_event→ Subtype of interaction (disjoint)
-- ══════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
-- 2.01  PERSON  (Supertype — Hierarchy 1)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE person (
    national_id     VARCHAR(20)  NOT NULL  COMMENT 'Uganda NIN — primary key',
    full_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE         NOT NULL,
    gender          ENUM('Male','Female','Other') NOT NULL,
    phone_number    VARCHAR(15)  NOT NULL,
    email           VARCHAR(100) NULL,
    district        VARCHAR(60)  NOT NULL,
    village_lc1     VARCHAR(80)  NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP 
                                 ON UPDATE CURRENT_TIMESTAMP,
    -- Derived attribute: age → computed in vw_person_full
    CONSTRAINT pk_person 
        PRIMARY KEY (national_id),
    CONSTRAINT chk_person_phone 
        CHECK (phone_number REGEXP '^[0-9+][0-9 \\-]{6,14}$'),
    -- Fixed: Using a static date instead of CURDATE()
    CONSTRAINT chk_person_dob 
        CHECK (date_of_birth >= '1900-01-01')
) ENGINE = InnoDB 
  COMMENT = 'Supertype — shared identity attributes for all stakeholders';

-- ────────────────────────────────────────────────────────────────
-- 2.02  FARMER  (Subtype L1 of PERSON, overlapping with EXT_WORKER)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE farmer (
    farmer_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    national_id        VARCHAR(20)  NOT NULL,
    registration_date  DATE         NOT NULL,
    cooperative_member TINYINT(1)   NOT NULL DEFAULT 0
                       COMMENT '1 = active cooperative member',
    -- Derived: total_farms → computed in vw_farmer_summary
    CONSTRAINT pk_farmer     PRIMARY KEY (farmer_id),
    CONSTRAINT uq_farmer_nid UNIQUE      (national_id),
    CONSTRAINT fk_farmer_person
        FOREIGN KEY (national_id) REFERENCES person(national_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  COMMENT = 'Subtype of PERSON — coffee farmers registered with the Ministry';


-- ────────────────────────────────────────────────────────────────
-- 2.03  EXTENSION_WORKER  (Subtype L1 of PERSON, overlapping)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE extension_worker (
    staff_id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    national_id     VARCHAR(20)   NOT NULL,
    qualification   VARCHAR(100)  NOT NULL,
    expertise_area  VARCHAR(100)  NOT NULL,
    assigned_region VARCHAR(80)   NOT NULL,
    hire_date       DATE          NOT NULL,
    CONSTRAINT pk_ext_worker     PRIMARY KEY (staff_id),
    CONSTRAINT uq_ext_worker_nid UNIQUE      (national_id),
    CONSTRAINT fk_ext_worker_person
        FOREIGN KEY (national_id) REFERENCES person(national_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  COMMENT = 'Subtype of PERSON — Ministry field and training staff';


-- ────────────────────────────────────────────────────────────────
-- 2.04  SMALLHOLDER_FARMER  (Subtype L2 of FARMER — disjoint)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE smallholder_farmer (
    sh_id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    farmer_id         INT UNSIGNED NOT NULL,
    priority_rating   ENUM('High','Medium','Low') NOT NULL DEFAULT 'Medium',
    subsistence_level VARCHAR(60)  NULL,
    CONSTRAINT pk_sh_farmer    PRIMARY KEY (sh_id),
    CONSTRAINT uq_sh_farmer_id UNIQUE      (farmer_id),
    CONSTRAINT fk_sh_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Subtype L2 of FARMER — farm under 2 acres (disjoint, total)';


-- ────────────────────────────────────────────────────────────────
-- 2.05  COMMERCIAL_FARMER  (Subtype L2 of FARMER — disjoint)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE commercial_farmer (
    comm_id           INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    farmer_id         INT UNSIGNED   NOT NULL,
    business_reg_no   VARCHAR(40)    NOT NULL,
    annual_export_vol DECIMAL(10,2)  NULL  COMMENT 'kg exported per year',
    CONSTRAINT pk_comm_farmer    PRIMARY KEY (comm_id),
    CONSTRAINT uq_comm_farmer_id UNIQUE      (farmer_id),
    CONSTRAINT uq_business_reg   UNIQUE      (business_reg_no),
    CONSTRAINT fk_comm_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Subtype L2 of FARMER — farm 2+ acres (disjoint, total)';


-- ────────────────────────────────────────────────────────────────
-- 2.06  FIELD_OFFICER  (Subtype L2 of EXT_WORKER — disjoint, partial)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE field_officer (
    fo_id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id        INT UNSIGNED NOT NULL,
    farms_assigned  INT UNSIGNED NOT NULL DEFAULT 0,
    last_visit_date DATE         NULL,
    CONSTRAINT pk_field_officer PRIMARY KEY (fo_id),
    CONSTRAINT uq_fo_staff      UNIQUE      (staff_id),
    CONSTRAINT fk_fo_worker
        FOREIGN KEY (staff_id) REFERENCES extension_worker(staff_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Subtype L2 of EXT_WORKER — visits individual farms';


-- ────────────────────────────────────────────────────────────────
-- 2.07  TRAINER  (Subtype L2 of EXT_WORKER — disjoint, partial)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE trainer (
    tr_id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id           INT UNSIGNED NOT NULL,
    specialisation     VARCHAR(100) NOT NULL,
    sessions_conducted INT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT pk_trainer      PRIMARY KEY (tr_id),
    CONSTRAINT uq_trainer_staff UNIQUE     (staff_id),
    CONSTRAINT fk_trainer_worker
        FOREIGN KEY (staff_id) REFERENCES extension_worker(staff_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Subtype L2 of EXT_WORKER — conducts group training sessions';


-- ────────────────────────────────────────────────────────────────
-- 2.08  COOPERATIVE
-- ────────────────────────────────────────────────────────────────
CREATE TABLE cooperative (
    coop_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    coop_name        VARCHAR(120) NOT NULL,
    registration_no  VARCHAR(40)  NOT NULL,
    district         VARCHAR(60)  NOT NULL,
    chairperson      VARCHAR(100) NOT NULL,
    date_established DATE         NOT NULL,
    -- Derived: member_count → computed in vw_cooperative_summary
    CONSTRAINT pk_cooperative  PRIMARY KEY (coop_id),
    CONSTRAINT uq_coop_reg_no  UNIQUE      (registration_no)
) ENGINE = InnoDB
  COMMENT = 'Farmer cooperatives registered with the Ministry';


-- ────────────────────────────────────────────────────────────────
-- 2.09  COOP_MEMBERSHIP  (Associative — FARMER ↔ COOPERATIVE M:N)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE coop_membership (
    farmer_id         INT UNSIGNED NOT NULL,
    coop_id           INT UNSIGNED NOT NULL,
    join_date         DATE         NOT NULL,
    membership_status ENUM('Active','Suspended','Withdrawn')
                      NOT NULL DEFAULT 'Active',
    CONSTRAINT pk_coop_membership PRIMARY KEY (farmer_id, coop_id),
    CONSTRAINT fk_cm_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cm_coop
        FOREIGN KEY (coop_id) REFERENCES cooperative(coop_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB
  COMMENT = 'Bridge — resolves FARMER to COOPERATIVE M:N';


-- ────────────────────────────────────────────────────────────────
-- 2.10  FARM  (Supertype — Hierarchy 2)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE farm (
    farm_id           INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    farmer_id         INT UNSIGNED   NOT NULL,
    gps_latitude      DECIMAL(10,7)  NULL,
    gps_longitude     DECIMAL(10,7)  NULL,
    land_size_acres   DECIMAL(8,2)   NOT NULL,
    soil_type         VARCHAR(60)    NULL,
    water_source      VARCHAR(80)    NULL,
    altitude_m        INT            NULL,
    district          VARCHAR(60)    NOT NULL,
    village           VARCHAR(80)    NOT NULL,
    registration_date DATE           NOT NULL,
    CONSTRAINT pk_farm PRIMARY KEY (farm_id),
    CONSTRAINT fk_farm_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_farm_size
        CHECK (land_size_acres > 0),
    CONSTRAINT chk_farm_altitude
        CHECK (altitude_m IS NULL OR altitude_m BETWEEN 0 AND 5000)
) ENGINE = InnoDB
  COMMENT = 'Supertype — physical farm plot owned by a registered farmer';


-- ────────────────────────────────────────────────────────────────
-- 2.11-13  FARM Subtypes (overlapping, total)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE robusta_farm (
    rf_id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    farm_id          INT UNSIGNED  NOT NULL,
    robusta_yield_kg DECIMAL(10,2) NULL,
    altitude_range   VARCHAR(40)   NULL,
    CONSTRAINT pk_robusta_farm PRIMARY KEY (rf_id),
    CONSTRAINT uq_rf_farm_id   UNIQUE      (farm_id),
    CONSTRAINT fk_rf_farm
        FOREIGN KEY (farm_id) REFERENCES farm(farm_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_robusta_yield
        CHECK (robusta_yield_kg IS NULL OR robusta_yield_kg >= 0)
) ENGINE = InnoDB COMMENT = 'Subtype of FARM — Robusta coffee plot';

CREATE TABLE arabica_farm (
    af_id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    farm_id          INT UNSIGNED  NOT NULL,
    arabica_yield_kg DECIMAL(10,2) NULL,
    altitude_range   VARCHAR(40)   NULL,
    CONSTRAINT pk_arabica_farm PRIMARY KEY (af_id),
    CONSTRAINT uq_af_farm_id   UNIQUE      (farm_id),
    CONSTRAINT fk_af_farm
        FOREIGN KEY (farm_id) REFERENCES farm(farm_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_arabica_yield
        CHECK (arabica_yield_kg IS NULL OR arabica_yield_kg >= 0)
) ENGINE = InnoDB COMMENT = 'Subtype of FARM — Arabica coffee plot';

CREATE TABLE mixed_farm (
    mf_id       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    farm_id     INT UNSIGNED  NOT NULL,
    robusta_pct DECIMAL(5,2)  NOT NULL,
    arabica_pct DECIMAL(5,2)  NOT NULL,
    CONSTRAINT pk_mixed_farm  PRIMARY KEY (mf_id),
    CONSTRAINT uq_mf_farm_id  UNIQUE      (farm_id),
    CONSTRAINT fk_mf_farm
        FOREIGN KEY (farm_id) REFERENCES farm(farm_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_mf_pct_sum
        CHECK (robusta_pct + arabica_pct = 100),
    CONSTRAINT chk_mf_pct_range
        CHECK (robusta_pct BETWEEN 0 AND 100
           AND arabica_pct BETWEEN 0 AND 100)
) ENGINE = InnoDB COMMENT = 'Subtype of FARM — grows both varieties';


-- ────────────────────────────────────────────────────────────────
-- 2.14  COFFEE_VARIETY
-- ────────────────────────────────────────────────────────────────
CREATE TABLE coffee_variety (
    variety_id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    variety_name          VARCHAR(80)   NOT NULL,
    variety_type          ENUM('Robusta','Arabica') NOT NULL,
    avg_yield_kg_per_acre DECIMAL(8,2)  NULL,
    disease_resistance    VARCHAR(80)   NULL,
    ideal_altitude_m      INT           NULL,
    CONSTRAINT pk_coffee_variety PRIMARY KEY (variety_id),
    CONSTRAINT uq_variety_name   UNIQUE      (variety_name)
) ENGINE = InnoDB COMMENT = 'Coffee variety catalogue maintained by the Ministry';


-- ────────────────────────────────────────────────────────────────
-- 2.15  FARM_VARIETY  (Associative — FARM ↔ COFFEE_VARIETY M:N)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE farm_variety (
    farm_id              INT UNSIGNED NOT NULL,
    variety_id           INT UNSIGNED NOT NULL,
    area_allocated_acres DECIMAL(8,2) NOT NULL,
    year_planted         YEAR         NOT NULL,
    CONSTRAINT pk_farm_variety PRIMARY KEY (farm_id, variety_id),
    CONSTRAINT fk_fv_farm
        FOREIGN KEY (farm_id)    REFERENCES farm(farm_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_fv_variety
        FOREIGN KEY (variety_id) REFERENCES coffee_variety(variety_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_fv_area CHECK (area_allocated_acres > 0)
) ENGINE = InnoDB COMMENT = 'Bridge — resolves FARM to COFFEE_VARIETY M:N';


-- ────────────────────────────────────────────────────────────────
-- 2.16  PRODUCTION_RECORD  (Weak entity — depends on FARM)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE production_record (
    record_id     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    farm_id       INT UNSIGNED  NOT NULL,
    season        ENUM('Long','Short') NOT NULL,
    year          YEAR          NOT NULL,
    harvest_date  DATE          NULL,
    yield_kg      DECIMAL(10,2) NOT NULL DEFAULT 0,
    quality_grade ENUM('A','B','C','Ungraded') NOT NULL DEFAULT 'Ungraded',
    pest_issues   TEXT          NULL,
    notes         TEXT          NULL,
    -- Derived: revenue_estimate → computed in vw_production_revenue
    CONSTRAINT pk_production_record  PRIMARY KEY (record_id),
    CONSTRAINT uq_prod_farm_ssn_yr   UNIQUE (farm_id, season, year),
    CONSTRAINT fk_pr_farm
        FOREIGN KEY (farm_id) REFERENCES farm(farm_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_pr_yield
        CHECK (yield_kg >= 0)
) ENGINE = InnoDB
  COMMENT = 'Weak entity — one seasonal harvest record per farm';


-- ────────────────────────────────────────────────────────────────
-- 2.17  SUPPLIER
-- ────────────────────────────────────────────────────────────────
CREATE TABLE supplier (
    supplier_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    supplier_name VARCHAR(120) NOT NULL,
    contact_person VARCHAR(100) NULL,
    phone         VARCHAR(15)  NOT NULL,
    location      VARCHAR(100) NOT NULL,
    certification VARCHAR(120) NULL,
    CONSTRAINT pk_supplier PRIMARY KEY (supplier_id)
) ENGINE = InnoDB COMMENT = 'Approved suppliers of seedlings and inputs';


-- ────────────────────────────────────────────────────────────────
-- 2.18  RESOURCE  (Supertype — Hierarchy 3)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE resource (
    resource_id        INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    supplier_id        INT UNSIGNED   NOT NULL,
    batch_no           VARCHAR(40)    NOT NULL,
    date_received      DATE           NOT NULL,
    quantity_available INT UNSIGNED   NOT NULL DEFAULT 0,
    unit_cost_ugx      DECIMAL(12,2)  NOT NULL DEFAULT 0,
    -- Derived: total_value → computed in vw_resource_value
    CONSTRAINT pk_resource       PRIMARY KEY (resource_id),
    CONSTRAINT uq_resource_batch UNIQUE      (batch_no),
    CONSTRAINT fk_resource_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_resource_qty  CHECK (quantity_available >= 0),
    CONSTRAINT chk_resource_cost CHECK (unit_cost_ugx >= 0)
) ENGINE = InnoDB
  COMMENT = 'Supertype — all procured items managed by the Ministry';


-- ────────────────────────────────────────────────────────────────
-- 2.19-20  RESOURCE Subtypes (disjoint, total)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE seedling (
    seedling_id      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    resource_id      INT UNSIGNED  NOT NULL,
    variety_id       INT UNSIGNED  NULL,
    variety_label    ENUM('Robusta','Arabica') NOT NULL,
    germination_rate DECIMAL(5,2)  NULL  COMMENT 'Percentage 0–100',
    age_weeks        INT UNSIGNED  NULL,
    nursery_source   VARCHAR(100)  NULL,
    CONSTRAINT pk_seedling    PRIMARY KEY (seedling_id),
    CONSTRAINT uq_seedling_rid UNIQUE     (resource_id),
    CONSTRAINT fk_seedling_resource
        FOREIGN KEY (resource_id) REFERENCES resource(resource_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_seedling_variety
        FOREIGN KEY (variety_id)  REFERENCES coffee_variety(variety_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_seedling_germ
        CHECK (germination_rate IS NULL
            OR germination_rate BETWEEN 0 AND 100)
) ENGINE = InnoDB COMMENT = 'Subtype of RESOURCE — coffee seedlings (disjoint)';

CREATE TABLE input (
    input_id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    resource_id              INT UNSIGNED NOT NULL,
    input_type   ENUM('Fertiliser','Pesticide','Tool','Other') NOT NULL,
    weight_kg                DECIMAL(10,2) NULL,
    application_instructions TEXT          NULL,
    expiry_date              DATE          NULL,
    CONSTRAINT pk_input    PRIMARY KEY (input_id),
    CONSTRAINT uq_input_rid UNIQUE     (resource_id),
    CONSTRAINT fk_input_resource
        FOREIGN KEY (resource_id) REFERENCES resource(resource_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Subtype of RESOURCE — fertilisers, pesticides, tools (disjoint)';


-- ────────────────────────────────────────────────────────────────
-- 2.21  TRAINING_PROGRAMME
-- ────────────────────────────────────────────────────────────────
CREATE TABLE training_programme (
    programme_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    programme_name   VARCHAR(120) NOT NULL,
    topic            VARCHAR(200) NOT NULL,
    start_date       DATE         NOT NULL,
    end_date         DATE         NOT NULL,
    venue            VARCHAR(120) NOT NULL,
    max_participants INT UNSIGNED NOT NULL DEFAULT 30,
    CONSTRAINT pk_training_programme PRIMARY KEY (programme_id),
    CONSTRAINT chk_tp_dates CHECK (end_date >= start_date),
    CONSTRAINT chk_tp_max   CHECK (max_participants > 0)
) ENGINE = InnoDB COMMENT = 'Ministry-organised training and sensitisation events';


-- ────────────────────────────────────────────────────────────────
-- 2.22  PROGRAMME_ENROLMENT  (Associative — FARMER ↔ TRAINING M:N)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE programme_enrolment (
    farmer_id         INT UNSIGNED NOT NULL,
    programme_id      INT UNSIGNED NOT NULL,
    enrolment_date    DATE         NOT NULL,
    completion_status ENUM('Enrolled','Completed','Dropped')
                      NOT NULL DEFAULT 'Enrolled',
    certificate_no    VARCHAR(60)  NULL,
    CONSTRAINT pk_programme_enrolment PRIMARY KEY (farmer_id, programme_id),
    CONSTRAINT fk_pe_farmer
        FOREIGN KEY (farmer_id)    REFERENCES farmer(farmer_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pe_programme
        FOREIGN KEY (programme_id) REFERENCES training_programme(programme_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB COMMENT = 'Bridge — resolves FARMER to TRAINING_PROGRAMME M:N';


-- ────────────────────────────────────────────────────────────────
-- 2.23  INTERACTION  (Supertype — Hierarchy 4)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE interaction (
    activity_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    farmer_id       INT UNSIGNED NOT NULL,
    activity_date   DATE         NOT NULL,
    district        VARCHAR(60)  NOT NULL,
    activity_status ENUM('Completed','Pending','Cancelled')
                    NOT NULL DEFAULT 'Pending',
    CONSTRAINT pk_interaction PRIMARY KEY (activity_id),
    CONSTRAINT fk_interaction_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB
  COMMENT = 'Supertype — all Ministry-farmer service interactions';


-- ────────────────────────────────────────────────────────────────
-- 2.24-25  INTERACTION Subtypes (disjoint, total)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE advisory_session (
    session_id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    activity_id        INT UNSIGNED NOT NULL,
    staff_id           INT UNSIGNED NOT NULL,
    advice_summary     TEXT         NOT NULL,
    follow_up_required TINYINT(1)   NOT NULL DEFAULT 0,
    next_visit_date    DATE         NULL,
    session_type   ENUM('Individual','Group','Remote')
                       NOT NULL DEFAULT 'Individual',
    CONSTRAINT pk_advisory_session PRIMARY KEY (session_id),
    CONSTRAINT uq_as_activity_id   UNIQUE      (activity_id),
    CONSTRAINT fk_as_interaction
        FOREIGN KEY (activity_id) REFERENCES interaction(activity_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_as_worker
        FOREIGN KEY (staff_id)    REFERENCES extension_worker(staff_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB COMMENT = 'Subtype of INTERACTION — advisory farm visit (disjoint)';

CREATE TABLE distribution_event (
    event_id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    activity_id            INT UNSIGNED NOT NULL,
    resource_id            INT UNSIGNED NOT NULL,
    quantity_given         INT UNSIGNED NOT NULL,
    distribution_point     VARCHAR(120) NOT NULL,
    received_by            VARCHAR(100) NOT NULL,
    acknowledgement_signed TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT pk_distribution_event PRIMARY KEY (event_id),
    CONSTRAINT uq_de_activity_id     UNIQUE      (activity_id),
    CONSTRAINT fk_de_interaction
        FOREIGN KEY (activity_id) REFERENCES interaction(activity_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_de_resource
        FOREIGN KEY (resource_id) REFERENCES resource(resource_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_de_qty CHECK (quantity_given > 0)
) ENGINE = InnoDB COMMENT = 'Subtype of INTERACTION — physical goods delivery (disjoint)';



-- ══════════════════════════════════════════════════════════════════
-- SECTION 3: INDEXES
-- Additional indexes beyond auto-indexed PKs and FKs.
-- ══════════════════════════════════════════════════════════════════

CREATE INDEX idx_person_district     ON person(district);
CREATE INDEX idx_person_full_name    ON person(full_name);
CREATE INDEX idx_farm_farmer         ON farm(farmer_id);
CREATE INDEX idx_farm_district       ON farm(district);
CREATE INDEX idx_prod_year           ON production_record(year);
CREATE INDEX idx_prod_quality        ON production_record(quality_grade);
CREATE INDEX idx_interaction_date    ON interaction(activity_date);
CREATE INDEX idx_interaction_status  ON interaction(activity_status);
CREATE INDEX idx_advisory_worker     ON advisory_session(staff_id);
CREATE INDEX idx_dist_resource       ON distribution_event(resource_id);
CREATE INDEX idx_resource_batch      ON resource(batch_no);


-- ══════════════════════════════════════════════════════════════════
-- SECTION 4: VIEWS  (Derived Attributes & Reporting)
-- ══════════════════════════════════════════════════════════════════

-- ── View 1: Person with derived AGE ──────────────────────────────
CREATE OR REPLACE VIEW vw_person_full AS
SELECT
    p.national_id,
    p.full_name,
    p.date_of_birth,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,   -- DERIVED
    p.gender,
    p.phone_number,
    p.email,
    p.district,
    p.village_lc1,
    p.created_at
FROM person p;


-- ── View 2: Farmer summary — total_farms, total_acres, category ──
CREATE OR REPLACE VIEW vw_farmer_summary AS
SELECT
    f.farmer_id,
    p.full_name,
    p.national_id,
    p.phone_number,
    p.district,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE())    AS age,
    f.registration_date,
    f.cooperative_member,
    COUNT(fm.farm_id)                                  AS total_farms,     -- DERIVED
    COALESCE(SUM(fm.land_size_acres), 0)               AS total_land_acres, -- DERIVED
    CASE
        WHEN sh.sh_id   IS NOT NULL THEN 'Smallholder'
        WHEN cm.comm_id IS NOT NULL THEN 'Commercial'
        ELSE 'Unclassified'
    END                                                AS farmer_category
FROM farmer f
JOIN  person               p  ON p.national_id  = f.national_id
LEFT JOIN farm             fm ON fm.farmer_id   = f.farmer_id
LEFT JOIN smallholder_farmer sh ON sh.farmer_id = f.farmer_id
LEFT JOIN commercial_farmer  cm ON cm.farmer_id = f.farmer_id
GROUP BY f.farmer_id, p.full_name, p.national_id, p.phone_number,
         p.district, p.date_of_birth, f.registration_date,
         f.cooperative_member, sh.sh_id, cm.comm_id;


-- ── View 3: Resource with derived TOTAL_VALUE and resource type ──
CREATE OR REPLACE VIEW vw_resource_value AS
SELECT
    r.resource_id,
    r.batch_no,
    r.date_received,
    r.quantity_available,
    r.unit_cost_ugx,
    (r.quantity_available * r.unit_cost_ugx)   AS total_value_ugx,  -- DERIVED
    s.supplier_name,
    s.location                                 AS supplier_location,
    CASE
        WHEN se.seedling_id IS NOT NULL THEN 'Seedling'
        WHEN ip.input_id    IS NOT NULL THEN 'Input'
        ELSE 'Unclassified'
    END                                        AS resource_type
FROM resource r
JOIN  supplier s  ON s.supplier_id  = r.supplier_id
LEFT JOIN seedling se ON se.resource_id = r.resource_id
LEFT JOIN input    ip ON ip.resource_id = r.resource_id;


-- ── View 4: Cooperative with derived MEMBER_COUNT ────────────────
CREATE OR REPLACE VIEW vw_cooperative_summary AS
SELECT
    c.coop_id,
    c.coop_name,
    c.registration_no,
    c.district,
    c.chairperson,
    c.date_established,
    COUNT(cm.farmer_id)  AS member_count  -- DERIVED
FROM cooperative c
LEFT JOIN coop_membership cm
       ON cm.coop_id          = c.coop_id
      AND cm.membership_status = 'Active'
GROUP BY c.coop_id, c.coop_name, c.registration_no,
         c.district, c.chairperson, c.date_established;


-- ── View 5: Production with derived REVENUE_ESTIMATE ─────────────
CREATE OR REPLACE VIEW vw_production_revenue AS
SELECT
    pr.record_id,
    pr.farm_id,
    fm.district,
    fm.village,
    p.full_name           AS farmer_name,
    p.phone_number,
    pr.season,
    pr.year,
    pr.harvest_date,
    pr.yield_kg,
    pr.quality_grade,
    pr.pest_issues,
    (pr.yield_kg * 3500)  AS revenue_estimate_ugx  -- DERIVED (3500 UGX/kg)
FROM production_record pr
JOIN farm   fm ON fm.farm_id    = pr.farm_id
JOIN farmer f  ON f.farmer_id   = fm.farmer_id
JOIN person p  ON p.national_id = f.national_id;


-- ── View 6: Full interaction log (UNION of both subtypes) ─────────
CREATE OR REPLACE VIEW vw_interaction_log AS
SELECT
    i.activity_id,
    i.activity_date,
    i.district,
    i.activity_status,
    p.full_name          AS farmer_name,
    p.phone_number,
    'Advisory Session'   AS interaction_type,
    pw.full_name         AS worker_name,
    a.session_type,
    a.advice_summary     AS detail,
    a.follow_up_required,
    a.next_visit_date,
    NULL                 AS resource_batch,
    NULL                 AS quantity_given
FROM interaction i
JOIN farmer  f  ON f.farmer_id    = i.farmer_id
JOIN person  p  ON p.national_id  = f.national_id
JOIN advisory_session  a  ON a.activity_id  = i.activity_id
JOIN extension_worker ew  ON ew.staff_id    = a.staff_id
JOIN person           pw  ON pw.national_id = ew.national_id
UNION ALL
SELECT
    i.activity_id,
    i.activity_date,
    i.district,
    i.activity_status,
    p.full_name          AS farmer_name,
    p.phone_number,
    'Distribution Event' AS interaction_type,
    NULL                 AS worker_name,
    NULL                 AS session_type,
    NULL                 AS detail,
    NULL                 AS follow_up_required,
    NULL                 AS next_visit_date,
    r.batch_no           AS resource_batch,
    d.quantity_given
FROM interaction i
JOIN farmer f ON f.farmer_id    = i.farmer_id
JOIN person p ON p.national_id  = f.national_id
JOIN distribution_event d ON d.activity_id = i.activity_id
JOIN resource           r ON r.resource_id = d.resource_id;


-- ── View 7: Extension worker profile with derived ROLE & SERVICE YEARS
CREATE OR REPLACE VIEW vw_worker_profile AS
SELECT
    ew.staff_id,
    p.full_name,
    p.national_id,
    p.phone_number,
    p.district,
    ew.qualification,
    ew.expertise_area,
    ew.assigned_region,
    ew.hire_date,
    TIMESTAMPDIFF(YEAR, ew.hire_date, CURDATE()) AS years_of_service, -- DERIVED
    CASE
        WHEN fo.fo_id IS NOT NULL AND tr.tr_id IS NOT NULL
             THEN 'Field Officer & Trainer'
        WHEN fo.fo_id IS NOT NULL THEN 'Field Officer'
        WHEN tr.tr_id IS NOT NULL THEN 'Trainer'
        ELSE 'Unclassified'
    END AS worker_role
FROM extension_worker ew
JOIN  person        p  ON p.national_id = ew.national_id
LEFT JOIN field_officer fo ON fo.staff_id = ew.staff_id
LEFT JOIN trainer       tr ON tr.staff_id = ew.staff_id;


-- ══════════════════════════════════════════════════════════════════
-- SECTION 5: STORED FUNCTIONS
-- ══════════════════════════════════════════════════════════════════

DELIMITER $$

-- ── Function 1: Return farmer type label ─────────────────────────
CREATE FUNCTION fn_farmer_type(p_farmer_id INT UNSIGNED)
RETURNS VARCHAR(20)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_type VARCHAR(20) DEFAULT 'Unclassified';
    IF EXISTS (SELECT 1 FROM smallholder_farmer
               WHERE farmer_id = p_farmer_id) THEN
        SET v_type = 'Smallholder';
    ELSEIF EXISTS (SELECT 1 FROM commercial_farmer
                   WHERE farmer_id = p_farmer_id) THEN
        SET v_type = 'Commercial';
    END IF;
    RETURN v_type;
END$$

-- ── Function 2: Total yield for a farm across all seasons ─────────
CREATE FUNCTION fn_total_yield(p_farm_id INT UNSIGNED)
RETURNS DECIMAL(12,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2) DEFAULT 0;
    SELECT COALESCE(SUM(yield_kg), 0) INTO v_total
      FROM production_record WHERE farm_id = p_farm_id;
    RETURN v_total;
END$$

-- ── Function 3: Human-readable stock status label ─────────────────
CREATE FUNCTION fn_stock_status(p_qty INT UNSIGNED)
RETURNS VARCHAR(15)
DETERMINISTIC NO SQL
BEGIN
    RETURN CASE
        WHEN p_qty = 0   THEN 'Out of Stock'
        WHEN p_qty < 100 THEN 'Low Stock'
        WHEN p_qty < 1000 THEN 'Adequate'
        ELSE                   'Well Stocked'
    END;
END$$

-- ── Function 4: Revenue estimate in UGX ──────────────────────────
CREATE FUNCTION fn_revenue_estimate(
    p_yield_kg  DECIMAL(10,2),
    p_price_ugx DECIMAL(10,2)
)
RETURNS DECIMAL(14,2)
DETERMINISTIC NO SQL
BEGIN
    RETURN ROUND(p_yield_kg * p_price_ugx, 2);
END$$

-- ── Function 5: Days since a field officer's last visit ───────────
CREATE FUNCTION fn_days_since_visit(p_staff_id INT UNSIGNED)
RETURNS INT
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_last DATE;
    SELECT last_visit_date INTO v_last
      FROM field_officer WHERE staff_id = p_staff_id;
    IF v_last IS NULL THEN RETURN -1; END IF;
    RETURN DATEDIFF(CURDATE(), v_last);
END$$

DELIMITER ;


-- ══════════════════════════════════════════════════════════════════
-- SECTION 6: STORED PROCEDURES
-- ══════════════════════════════════════════════════════════════════

DELIMITER $$

-- ── Procedure 1: Register a new farmer (atomic) ──────────────────
-- Inserts PERSON + FARMER + subtype (Smallholder or Commercial)
-- in a single transaction. Rolls back entirely on any error.
CREATE PROCEDURE sp_register_farmer(
    IN p_national_id  VARCHAR(20),
    IN p_full_name    VARCHAR(100),
    IN p_dob          DATE,
    IN p_gender       VARCHAR(10),
    IN p_phone        VARCHAR(15),
    IN p_email        VARCHAR(100),
    IN p_district     VARCHAR(60),
    IN p_village      VARCHAR(80),
    IN p_coop_member  TINYINT(1),
    IN p_farmer_type  ENUM('Smallholder','Commercial'),
    IN p_priority     VARCHAR(10),   -- Smallholder only
    IN p_business_reg VARCHAR(40)    -- Commercial only
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; RESIGNAL; END;

    START TRANSACTION;

    INSERT INTO person(national_id, full_name, date_of_birth, gender,
                       phone_number, email, district, village_lc1)
    VALUES (p_national_id, p_full_name, p_dob, p_gender,
            p_phone, p_email, p_district, p_village);

    INSERT INTO farmer(national_id, registration_date, cooperative_member)
    VALUES (p_national_id, CURDATE(), p_coop_member);

    IF p_farmer_type = 'Smallholder' THEN
        INSERT INTO smallholder_farmer(farmer_id, priority_rating)
        VALUES (LAST_INSERT_ID(), IFNULL(p_priority, 'Medium'));
    ELSE
        INSERT INTO commercial_farmer(farmer_id, business_reg_no)
        VALUES (LAST_INSERT_ID(), p_business_reg);
    END IF;

    COMMIT;
    SELECT 'Farmer registered successfully' AS result;
END$$


-- ── Procedure 2: Distribute a resource to a farmer (with stock check)
-- Validates stock, creates INTERACTION + DISTRIBUTION_EVENT,
-- deducts from stock. Rolls back if stock is insufficient.
CREATE PROCEDURE sp_distribute_resource(
    IN p_farmer_id   INT UNSIGNED,
    IN p_resource_id INT UNSIGNED,
    IN p_quantity    INT UNSIGNED,
    IN p_district    VARCHAR(60),
    IN p_point       VARCHAR(120),
    IN p_received_by VARCHAR(100)
)
BEGIN
    DECLARE v_activity_id INT UNSIGNED;
    DECLARE v_available   INT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; RESIGNAL; END;

    START TRANSACTION;

    SELECT quantity_available INTO v_available
      FROM resource WHERE resource_id = p_resource_id FOR UPDATE;

    IF v_available < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Insufficient stock — quantity exceeds available';
    END IF;

    INSERT INTO interaction(farmer_id, activity_date,
                            district, activity_status)
    VALUES (p_farmer_id, CURDATE(), p_district, 'Completed');
    SET v_activity_id = LAST_INSERT_ID();

    INSERT INTO distribution_event(
        activity_id, resource_id, quantity_given,
        distribution_point, received_by, acknowledgement_signed)
    VALUES (v_activity_id, p_resource_id, p_quantity,
            p_point, p_received_by, 1);

    UPDATE resource
       SET quantity_available = quantity_available - p_quantity
     WHERE resource_id = p_resource_id;

    COMMIT;
    SELECT CONCAT('Distributed ', p_quantity,
                  ' units. Activity ID: ', v_activity_id) AS result;
END$$


-- ── Procedure 3: Log an advisory session (atomic) ────────────────
CREATE PROCEDURE sp_log_advisory(
    IN p_farmer_id    INT UNSIGNED,
    IN p_staff_id     INT UNSIGNED,
    IN p_district     VARCHAR(60),
    IN p_advice       TEXT,
    IN p_follow_up    TINYINT(1),
    IN p_next_visit   DATE,
    IN p_session_type VARCHAR(20)
)
BEGIN
    DECLARE v_activity_id INT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; RESIGNAL; END;

    START TRANSACTION;

    INSERT INTO interaction(farmer_id, activity_date,
                            district, activity_status)
    VALUES (p_farmer_id, CURDATE(), p_district, 'Completed');
    SET v_activity_id = LAST_INSERT_ID();

    INSERT INTO advisory_session(
        activity_id, staff_id, advice_summary,
        follow_up_required, next_visit_date, session_type)
    VALUES (v_activity_id, p_staff_id, p_advice,
            p_follow_up, p_next_visit, p_session_type);

    COMMIT;
    SELECT CONCAT('Advisory session logged. Activity ID: ',
                  v_activity_id) AS result;
END$$


-- ── Procedure 4: Resolve a complaint ─────────────────────────────
CREATE PROCEDURE sp_resolve_complaint(
    IN p_complaint_id INT UNSIGNED,
    IN p_resolution   ENUM('Resolved','Dismissed')
)
BEGIN
    UPDATE complaint_feedback
       SET resolution_status = p_resolution,
           resolved_date     = CURDATE()
     WHERE complaint_id = p_complaint_id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Complaint ID not found';
    END IF;
    SELECT CONCAT('Complaint ', p_complaint_id,
                  ' marked as ', p_resolution) AS result;
END$$

DELIMITER ;


-- ══════════════════════════════════════════════════════════════════
-- SECTION 7: DISJOINT CONSTRAINT TRIGGERS
-- ══════════════════════════════════════════════════════════════════

DELIMITER $$

-- ── Trigger 1 & 2: ADVISORY_SESSION ↔ DISTRIBUTION_EVENT disjoint
CREATE TRIGGER trg_advisory_disjoint
BEFORE INSERT ON advisory_session
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM distribution_event
               WHERE activity_id = NEW.activity_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Disjoint violation: activity_id already used by distribution_event';
    END IF;
END$$

CREATE TRIGGER trg_distribution_disjoint
BEFORE INSERT ON distribution_event
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM advisory_session
               WHERE activity_id = NEW.activity_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Disjoint violation: activity_id already used by advisory_session';
    END IF;
END$$


-- ── Trigger 3 & 4: SMALLHOLDER_FARMER ↔ COMMERCIAL_FARMER disjoint
CREATE TRIGGER trg_sh_farmer_disjoint
BEFORE INSERT ON smallholder_farmer
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM commercial_farmer
               WHERE farmer_id = NEW.farmer_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Disjoint violation: farmer already classified as Commercial';
    END IF;
END$$

CREATE TRIGGER trg_comm_farmer_disjoint
BEFORE INSERT ON commercial_farmer
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM smallholder_farmer
               WHERE farmer_id = NEW.farmer_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Disjoint violation: farmer already classified as Smallholder';
    END IF;
END$$


-- ── Trigger 5 & 6: SEEDLING ↔ INPUT disjoint
CREATE TRIGGER trg_seedling_disjoint
BEFORE INSERT ON seedling
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM input
               WHERE resource_id = NEW.resource_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Disjoint violation: resource already classified as Input';
    END IF;
END$$

CREATE TRIGGER trg_input_disjoint
BEFORE INSERT ON input
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM seedling
               WHERE resource_id = NEW.resource_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Disjoint violation: resource already classified as Seedling';
    END IF;
END$$


-- ── Trigger 7: Auto-increment trainer session count ───────────────
CREATE TRIGGER trg_increment_sessions
AFTER INSERT ON advisory_session
FOR EACH ROW
BEGIN
    UPDATE trainer
       SET sessions_conducted = sessions_conducted + 1
     WHERE staff_id = NEW.staff_id;
END$$


-- ── Trigger 8: Auto-update field officer last visit date ──────────
CREATE TRIGGER trg_update_last_visit
AFTER INSERT ON advisory_session
FOR EACH ROW
BEGIN
    UPDATE field_officer
       SET last_visit_date = CURDATE()
     WHERE staff_id = NEW.staff_id;
END$$

DELIMITER ;


-- ══════════════════════════════════════════════════════════════════
-- SECTION 8: SAMPLE DATA (DML)
-- Inserts statements for all 23 tables.
-- Run in order — FK dependencies must be satisfied.
-- ══════════════════════════════════════════════════════════════════

-- 8.01 Persons ────────────────────────────────────────────────────
INSERT INTO person
    (national_id, full_name, date_of_birth, gender,
     phone_number, email, district, village_lc1)
VALUES
('CM901002B','Ssekandi Robert',    '1979-07-24','Male',  '0752100002', NULL,              'Wakiso', 'Buloba'),
('CM901003C','Nabirye Grace',      '1990-11-05','Female','0700100003','grace@gmail.com',  'Jinja',  'Mpumudde'),
('CM901004D','Kato Emmanuel',      '1982-01-18','Male',  '0783100004', NULL,              'Mukono', 'Kiwanga'),
('CM901005E','Namutebi Josephine', '1975-09-30','Female','0756100005', NULL,              'Kampala','Kawempe'),
('CM901006F','Opio Samuel',        '1988-06-15','Male',  '0771200006','opio@gmail.com',   'Lira',   'Adyel'),
('CM901007G','Akello Prossy',      '1992-04-22','Female','0702300007','akello@gmail.com', 'Gulu',   'Laroo');

-- 8.02 Farmers ────────────────────────────────────────────────────
INSERT INTO farmer(national_id, registration_date, cooperative_member)
VALUES
('CM901001A','2020-01-15',1),
('CM901002B','2019-06-20',0),
('CM901003C','2021-03-10',1),
('CM901006F','2022-08-01',1),
('CM901004D','2023-01-10',0);   -- overlapping: also an extension worker

-- 8.03 Extension workers ──────────────────────────────────────────
INSERT INTO extension_worker
    (national_id, qualification, expertise_area, assigned_region, hire_date)
VALUES
('CM901004D','BSc Agriculture',    'Coffee Agronomy','Mukono','2018-04-01'),
('CM901005E','Diploma Agriculture','Pest Management','Wakiso','2019-08-15'),
('CM901007G','MSc Agribusiness',   'Post-Harvest',   'Gulu',  '2021-05-10');

-- 8.04 Farmer subtypes (disjoint — each farmer in exactly one) ────
INSERT INTO smallholder_farmer(farmer_id, priority_rating, subsistence_level)
VALUES (1,'High','Low'), (3,'Medium',NULL), (4,'High','Low');

INSERT INTO commercial_farmer(farmer_id, business_reg_no, annual_export_vol)
VALUES (2,'BRN-2019-00234',12500.00), (5,'BRN-2023-00891',3200.00);

-- 8.05 Worker subtypes (disjoint, partial) ────────────────────────
INSERT INTO field_officer(staff_id, farms_assigned, last_visit_date)
VALUES (1,5,'2024-11-20'), (3,3,'2024-10-15');

INSERT INTO trainer(staff_id, specialisation, sessions_conducted)
VALUES (2,'Pest Management',12);

-- 8.06 Cooperatives ───────────────────────────────────────────────
INSERT INTO cooperative
    (coop_name, registration_no, district, chairperson, date_established)
VALUES
('Mukono Coffee Growers SACCO','COOP-MK-001','Mukono','Ssemakula John',  '2010-05-01'),
('Wakiso Farmers Union',       'COOP-WK-002','Wakiso','Namukasa Fatuma', '2015-03-18'),
('Northern Uganda Coffee CIG', 'COOP-GU-003','Gulu',  'Ocen Richard',    '2020-07-12');

-- 8.07 Cooperative memberships ─────────────────────────────────────
INSERT INTO coop_membership(farmer_id, coop_id, join_date, membership_status)
VALUES
(1,1,'2020-02-01','Active'),
(3,1,'2021-04-05','Active'),
(4,3,'2022-09-01','Active'),
(2,2,'2019-08-15','Active');

-- 8.08 Farms ───────────────────────────────────────────────────────
INSERT INTO farm
    (farmer_id, gps_latitude, gps_longitude, land_size_acres,
     soil_type, water_source, altitude_m, district, village, registration_date)
VALUES
(1,0.3536,32.7631,1.5,'Clay Loam', 'Rainwater',1100,'Mukono','Namanve',  '2020-01-20'),
(2,0.3721,32.5489,5.0,'Sandy Loam','Borehole',  1200,'Wakiso','Buloba',   '2019-07-10'),
(3,0.4502,33.2018,0.8,'Loam',      'Stream',     900,'Jinja', 'Mpumudde', '2021-03-15'),
(4,2.2745,32.9012,1.2,'Clay',      'Rainwater',  1050,'Lira', 'Adyel',    '2022-08-10'),
(2,0.3910,32.5601,3.5,'Sandy Loam','Borehole',   1180,'Wakiso','Nansana',  '2020-11-05');

-- 8.09 Farm subtypes (overlapping — farm 2 in robusta AND mixed) ───
INSERT INTO robusta_farm(farm_id, robusta_yield_kg, altitude_range)
VALUES (1,1200.00,'900-1200m'), (2,4500.00,'1100-1300m'), (4,980.00,'1000-1100m');

INSERT INTO arabica_farm(farm_id, arabica_yield_kg, altitude_range)
VALUES (3,600.00,'800-1000m'), (5,2100.00,'1100-1300m');

INSERT INTO mixed_farm(farm_id, robusta_pct, arabica_pct)
VALUES (2,60.00,40.00);

-- 8.10 Coffee varieties ───────────────────────────────────────────
INSERT INTO coffee_variety
    (variety_name, variety_type, avg_yield_kg_per_acre,
     disease_resistance, ideal_altitude_m)
VALUES
('Robusta CRI',  'Robusta',800,'CBD Resistant',      1050),
('Arabica SL28', 'Arabica',650,'Moderate Resistance',  950),
('Arabica K7',   'Arabica',700,'CBD Resistant',         900);

-- 8.11 Farm-variety assignments ───────────────────────────────────
INSERT INTO farm_variety(farm_id, variety_id, area_allocated_acres, year_planted)
VALUES
(1,1,1.5,2020),(2,1,3.0,2019),(2,2,2.0,2021),
(3,2,0.5,2021),(3,3,0.3,2021),(4,1,1.2,2022),
(5,2,2.0,2020),(5,1,1.5,2021);

-- 8.12 Production records (weak entity) ───────────────────────────
INSERT INTO production_record
    (farm_id, season, year, harvest_date, yield_kg, quality_grade, pest_issues)
VALUES
(1,'Long', 2023,'2023-10-15',1100.00,'A', NULL),
(1,'Short',2024,'2024-03-20', 480.00,'B', NULL),
(2,'Long', 2023,'2023-11-01',4200.00,'A', NULL),
(2,'Short',2024,'2024-03-10',1800.00,'A', NULL),
(3,'Long', 2023,'2023-09-25', 590.00,'B','Leaf rust on 20% of plants'),
(4,'Long', 2023,'2023-10-30', 870.00,'A', NULL),
(5,'Long', 2023,'2023-11-15',3100.00,'A', NULL);

-- 8.13 Suppliers ──────────────────────────────────────────────────
INSERT INTO supplier(supplier_name, contact_person, phone, location, certification)
VALUES
('UCDA Nurseries',       'Tendo Paul',   '0414700001','Entebbe','UCDA Certified'),
('AgriInputs Uganda Ltd','Birungi Sarah','0772500001','Kampala','NDA Registered');

-- 8.14 Resources ──────────────────────────────────────────────────
INSERT INTO resource
    (supplier_id, batch_no, date_received, quantity_available, unit_cost_ugx)
VALUES
(1,'BATCH-2024-001','2024-01-10',5000,1200),
(2,'BATCH-2024-002','2024-02-05', 200,45000),
(1,'BATCH-2024-003','2024-03-18',3000, 1200),
(2,'BATCH-2024-004','2024-04-02', 150,52000);

-- 8.15 Resource subtypes (disjoint — each in exactly one) ─────────
INSERT INTO seedling
    (resource_id, variety_id, variety_label, germination_rate,
     age_weeks, nursery_source)
VALUES
(1,1,'Robusta',92.5,12,'UCDA Entebbe Nursery'),
(3,2,'Arabica',88.0,10,'UCDA Entebbe Nursery');

INSERT INTO input
    (resource_id, input_type, weight_kg,
     application_instructions, expiry_date)
VALUES
(2,'Fertiliser',50.0,'Apply 200g per plant at onset of rains','2026-01-01'),
(4,'Pesticide', 25.0,'Dilute 10ml per litre, spray at dusk',  '2025-08-01');

-- 8.16 Training programmes ────────────────────────────────────────
INSERT INTO training_programme
    (programme_name, topic, start_date, end_date, venue, max_participants)
VALUES
('Good Agricultural Practices 2024',
 'Coffee quality improvement and post-harvest handling',
 '2024-04-01','2024-04-03','Mukono District Headquarters',50),
('Pest and Disease Management Workshop',
 'Identification and control of coffee wilt and leaf rust',
 '2024-06-10','2024-06-11','Wakiso Agricultural Training Centre',40);

-- 8.17 Programme enrolments ────────────────────────────────────────
INSERT INTO programme_enrolment
    (farmer_id, programme_id, enrolment_date, completion_status, certificate_no)
VALUES
(1,1,'2024-03-20','Completed','CERT-2024-001'),
(3,1,'2024-03-22','Completed','CERT-2024-002'),
(4,1,'2024-03-25','Enrolled', NULL),
(2,2,'2024-06-01','Completed','CERT-2024-003'),
(1,2,'2024-06-02','Completed','CERT-2024-004');

-- 8.18 Interactions — advisory sessions ───────────────────────────
INSERT INTO interaction(farmer_id, activity_date, district, activity_status)
VALUES
(1,'2024-11-20','Mukono','Completed'),
(3,'2024-10-15','Jinja', 'Completed'),
(4,'2024-11-05','Lira',  'Completed');

INSERT INTO advisory_session
    (activity_id, staff_id, advice_summary,
     follow_up_required, next_visit_date, session_type)
VALUES
(1,1,'Advised on timely weeding and mulching. Recommended CRI seedling replanting.',
    1,DATE_ADD('2024-11-20', INTERVAL 30 DAY),'Individual'),
(2,3,'Leaf rust treatment with copper fungicide recommended. Group demo arranged.',
    1,DATE_ADD('2024-10-15', INTERVAL 21 DAY),'Group'),
(3,1,'Soil pH testing advised. Lime application before next season recommended.',
    0,NULL,'Individual');

-- 8.19 Interactions — distribution events ─────────────────────────
INSERT INTO interaction(farmer_id, activity_date, district, activity_status)
VALUES
(3,'2024-11-10','Jinja', 'Completed'),
(2,'2024-09-20','Wakiso','Completed'),
(4,'2024-10-28','Lira',  'Completed');

INSERT INTO distribution_event
    (activity_id, resource_id, quantity_given,
     distribution_point, received_by, acknowledgement_signed)
VALUES
(4,1,200,'Jinja Sub-county Office',    'Nabirye Grace',   1),
(5,2, 50,'Wakiso NAADS Office',        'Ssekandi Robert', 1),
(6,3,300,'Lira District Headquarters', 'Opio Samuel',     1);

-- Manually deduct stock to match inserts above
UPDATE resource SET quantity_available = quantity_available - 200 WHERE resource_id = 1;
UPDATE resource SET quantity_available = quantity_available -  50 WHERE resource_id = 2;
UPDATE resource SET quantity_available = quantity_available - 300 WHERE resource_id = 3;

-- 8.20 Complaints (weak entity) ───────────────────────────────────
INSERT INTO complaint_feedback
    (farmer_id, date_raised, category, description, resolution_status)
VALUES
(1,CURDATE(),'Input Quality',
 'Fertiliser bag (BATCH-2024-002) had clumps — appears damp. Requesting replacement.',
 'Open'),
(3,'2024-10-20','Late Delivery',
 'Seedlings arrived 3 weeks late. Missed optimal planting window.',
 'In Progress'),
(2,'2024-09-25','Advisory',
 'Extension worker did not visit as scheduled. Assessment still pending.',
 'Open');


-- ══════════════════════════════════════════════════════════════════
-- SECTION 9: CONSTRAINT VALIDATION TESTS
-- Run each labelled block individually to verify constraints.
-- EXPECTED: PASS = insert should succeed
-- EXPECTED: FAIL = insert should be blocked by a constraint
-- ══════════════════════════════════════════════════════════════════

SELECT '═══════════════════════════════════════' AS '';
SELECT '  SECTION 9 — CONSTRAINT TESTS BEGIN   ' AS '';
SELECT '═══════════════════════════════════════' AS '';

-- ── T1: Foreign Key — farmer must reference a valid person ────────
SELECT '── T1a: EXPECTED FAIL — farmer with non-existent national_id' AS test;
INSERT IGNORE INTO farmer(national_id, registration_date, cooperative_member)
VALUES ('FAKE-999','2024-01-01',0);

SELECT '── T1b: EXPECTED PASS — valid person then farmer' AS test;
INSERT INTO person(national_id,full_name,date_of_birth,gender,phone_number,district,village_lc1)
VALUES('TEST001','Test Person','1990-01-01','Male','0700000001','Kampala','Kololo');
INSERT INTO farmer(national_id, registration_date, cooperative_member)
VALUES('TEST001', CURDATE(), 0);
SELECT CONCAT('Farmer created: farmer_id = ',
    (SELECT farmer_id FROM farmer WHERE national_id='TEST001')) AS result;


-- ── T2: Disjoint — SMALLHOLDER vs COMMERCIAL ─────────────────────
SELECT '── T2a: EXPECTED PASS — classify TEST001 as Smallholder' AS test;
INSERT INTO smallholder_farmer(farmer_id, priority_rating)
VALUES((SELECT farmer_id FROM farmer WHERE national_id='TEST001'), 'High');
SELECT 'Smallholder row inserted OK' AS result;

SELECT '── T2b: EXPECTED FAIL — same farmer also as Commercial' AS test;
INSERT IGNORE INTO commercial_farmer(farmer_id, business_reg_no)
VALUES((SELECT farmer_id FROM farmer WHERE national_id='TEST001'),'BRN-TEST-001');
SELECT IF(NOT EXISTS(
    SELECT 1 FROM commercial_farmer c
    JOIN farmer f ON f.farmer_id = c.farmer_id
    WHERE f.national_id = 'TEST001'),
    '  PASS: disjoint trigger blocked dual classification',
    '  FAIL: dual classification was allowed') AS result;


-- ── T3: Disjoint — SEEDLING vs INPUT ─────────────────────────────
SELECT '── T3a: EXPECTED PASS — classify batch as Seedling' AS test;
INSERT INTO resource(supplier_id,batch_no,date_received,quantity_available,unit_cost_ugx)
VALUES(1,'BATCH-TEST-001',CURDATE(),100,500);
INSERT INTO seedling(resource_id, variety_label, germination_rate)
VALUES(LAST_INSERT_ID(),'Robusta',90.0);
SELECT 'Seedling row inserted OK' AS result;

SELECT '── T3b: EXPECTED FAIL — same resource also as Input' AS test;
INSERT IGNORE INTO input(resource_id, input_type)
VALUES((SELECT resource_id FROM resource WHERE batch_no='BATCH-TEST-001'),'Fertiliser');
SELECT IF(NOT EXISTS(
    SELECT 1 FROM input i
    JOIN resource r ON r.resource_id = i.resource_id
    WHERE r.batch_no = 'BATCH-TEST-001'),
    '  PASS: disjoint trigger blocked dual classification',
    '  FAIL: dual classification was allowed') AS result;


-- ── T4: Disjoint — ADVISORY vs DISTRIBUTION ──────────────────────
SELECT '── T4a: EXPECTED PASS — create advisory session' AS test;
INSERT INTO interaction(farmer_id,activity_date,district,activity_status)
VALUES(1,CURDATE(),'Mukono','Completed');
SET @test_act = LAST_INSERT_ID();
INSERT INTO advisory_session(activity_id, staff_id, advice_summary)
VALUES(@test_act, 1, 'Test advisory for constraint check');
SELECT 'Advisory session created OK' AS result;

SELECT '── T4b: EXPECTED FAIL — same activity_id for distribution' AS test;
INSERT IGNORE INTO distribution_event(
    activity_id, resource_id, quantity_given,
    distribution_point, received_by)
VALUES(@test_act, 1, 10, 'Test Point', 'Test Person');
SELECT IF(NOT EXISTS(
    SELECT 1 FROM distribution_event WHERE activity_id = @test_act),
    '  PASS: disjoint trigger blocked dual use of activity_id',
    '  FAIL: dual subtype was allowed') AS result;


-- ── T5: CHECK constraints ─────────────────────────────────────────
SELECT '── T5a: EXPECTED FAIL — negative farm size' AS test;
INSERT IGNORE INTO farm(farmer_id,land_size_acres,district,village,registration_date)
VALUES(1,-2.0,'Mukono','Namanve',CURDATE());
SELECT IF(NOT EXISTS(SELECT 1 FROM farm WHERE land_size_acres < 0),
    '  PASS: CHECK blocked negative land size',
    '  FAIL: negative size was inserted') AS result;

SELECT '── T5b: EXPECTED FAIL — mixed farm pct summing to 110' AS test;
INSERT IGNORE INTO mixed_farm(farm_id, robusta_pct, arabica_pct)
VALUES(4, 60.00, 50.00);
SELECT IF(NOT EXISTS(
    SELECT 1 FROM mixed_farm WHERE robusta_pct + arabica_pct <> 100),
    '  PASS: CHECK blocked invalid percentages',
    '  FAIL: invalid percentages inserted') AS result;

SELECT '── T5c: EXPECTED FAIL — germination rate > 100' AS test;
INSERT INTO resource(supplier_id,batch_no,date_received,quantity_available,unit_cost_ugx)
VALUES(1,'BATCH-CHK-001',CURDATE(),50,1000);
INSERT IGNORE INTO seedling(resource_id, variety_label, germination_rate)
VALUES(LAST_INSERT_ID(),'Arabica',105.0);
SELECT IF(NOT EXISTS(SELECT 1 FROM seedling WHERE germination_rate > 100),
    '  PASS: CHECK blocked germination > 100',
    '  FAIL: invalid germination rate inserted') AS result;

SELECT '── T5d: EXPECTED FAIL — distribution qty = 0' AS test;
INSERT IGNORE INTO distribution_event(
    activity_id, resource_id, quantity_given,
    distribution_point, received_by)
SELECT MAX(activity_id)+99, 1, 0, 'X', 'Y' FROM interaction;
SELECT IF(NOT EXISTS(SELECT 1 FROM distribution_event WHERE quantity_given = 0),
    '  PASS: CHECK blocked zero quantity',
    '  FAIL: zero quantity inserted') AS result;


-- ── T6: NOT NULL ──────────────────────────────────────────────────
SELECT '── T6: EXPECTED FAIL — person with NULL full_name' AS test;
INSERT IGNORE INTO person(national_id,full_name,date_of_birth,gender,
    phone_number,district,village_lc1)
VALUES('NULLTEST',NULL,'1990-01-01','Male','0700000002','Kampala','Kololo');
SELECT IF(NOT EXISTS(SELECT 1 FROM person WHERE national_id='NULLTEST'),
    '  PASS: NOT NULL blocked null full_name',
    '  FAIL: null name was inserted') AS result;


-- ── T7: UNIQUE ────────────────────────────────────────────────────
SELECT '── T7: EXPECTED FAIL — duplicate national_id in farmer' AS test;
INSERT IGNORE INTO farmer(national_id, registration_date, cooperative_member)
VALUES('CM901001A', CURDATE(), 0);
SELECT IF((SELECT COUNT(*) FROM farmer WHERE national_id='CM901001A') = 1,
    '  PASS: UNIQUE blocked duplicate national_id',
    '  FAIL: duplicate was inserted') AS result;


-- ── T8: Stored procedure — insufficient stock rollback ────────────
SELECT '── T8: EXPECTED PASS — valid distribution via sp' AS test;
CALL sp_distribute_resource(1, 1, 10, 'Mukono', 'Test Office', 'Nakato Aisha');

SELECT '── T8: EXPECTED FAIL — quantity exceeds stock (procedure rolls back)' AS test;
CALL sp_distribute_resource(1, 1, 999999, 'Mukono', 'Test', 'Test');


-- ── T9: Function return values ────────────────────────────────────
SELECT '── T9: Function return values' AS test;
SELECT
    fn_farmer_type(1)              AS farmer_1_type,
    fn_farmer_type(2)              AS farmer_2_type,
    fn_total_yield(1)              AS farm_1_total_yield_kg,
    fn_stock_status(4800)          AS stock_4800,
    fn_stock_status(50)            AS stock_50,
    fn_stock_status(0)             AS stock_0,
    fn_revenue_estimate(1000,3500) AS revenue_1000kg_ugx,
    fn_days_since_visit(1)         AS days_since_officer_1_visit;


-- ── Cleanup test rows ─────────────────────────────────────────────
DELETE FROM advisory_session
 WHERE activity_id = @test_act;
DELETE FROM interaction  WHERE activity_id = @test_act;
DELETE FROM smallholder_farmer WHERE farmer_id =
    (SELECT farmer_id FROM farmer WHERE national_id='TEST001');
DELETE FROM farmer WHERE national_id = 'TEST001';
DELETE FROM person WHERE national_id IN ('TEST001','NULLTEST');
DELETE FROM seedling WHERE resource_id =
    (SELECT resource_id FROM resource WHERE batch_no='BATCH-TEST-001');
DELETE FROM resource WHERE batch_no IN ('BATCH-TEST-001','BATCH-CHK-001');

SELECT '═══════════════════════════════════════' AS '';
SELECT '  SECTION 9 — ALL CONSTRAINT TESTS DONE' AS '';
SELECT '═══════════════════════════════════════' AS '';


-- ══════════════════════════════════════════════════════════════════
-- SECTION 10: BUSINESS DEMONSTRATION QUERIES
-- Run each SELECT individually to see live data from the database.
-- ══════════════════════════════════════════════════════════════════

-- ── Q1: Farmer dashboard with category and farm totals ────────────
SELECT farmer_id, full_name, district,
       total_farms, total_land_acres,
       farmer_category, cooperative_member
FROM   vw_farmer_summary
ORDER  BY total_land_acres DESC;

-- ── Q2: Resource inventory with stock status ──────────────────────
SELECT resource_id, batch_no, resource_type,
       supplier_name, quantity_available,
       fn_stock_status(quantity_available) AS stock_status,
       total_value_ugx
FROM   vw_resource_value
ORDER  BY quantity_available;

-- ── Q3: Production performance with revenue estimates ─────────────
SELECT farmer_name, district, farm_id,
       season, year, yield_kg, quality_grade,
       fn_revenue_estimate(yield_kg, 3500) AS revenue_ugx
FROM   vw_production_revenue
ORDER  BY year DESC, yield_kg DESC;

-- ── Q4: Full interaction log ──────────────────────────────────────
SELECT activity_id, activity_date, farmer_name,
       interaction_type, worker_name,
       quantity_given, activity_status
FROM   vw_interaction_log
ORDER  BY activity_date DESC;

-- ── Q5: Cooperative membership counts ─────────────────────────────
SELECT coop_name, district, member_count
FROM   vw_cooperative_summary
ORDER  BY member_count DESC;

-- ── Q6: Worker profiles with service years ────────────────────────
SELECT staff_id, full_name, expertise_area,
       assigned_region, worker_role,
       years_of_service,
       fn_days_since_visit(staff_id) AS days_since_last_visit
FROM   vw_worker_profile;

-- ── Q7: Farms with total cumulative yield ─────────────────────────
SELECT f.farm_id, p.full_name AS farmer,
       f.district, f.village,
       f.land_size_acres,
       fn_total_yield(f.farm_id) AS total_yield_all_seasons_kg
FROM   farm f
JOIN   farmer fr ON fr.farmer_id   = f.farmer_id
JOIN   person p  ON p.national_id  = fr.national_id
ORDER  BY total_yield_all_seasons_kg DESC;

-- ── Q8: Open complaints pending resolution ────────────────────────
SELECT cf.complaint_id, p.full_name AS farmer,
       p.phone_number, cf.category,
       cf.date_raised, cf.description,
       cf.resolution_status
FROM   complaint_feedback cf
JOIN   farmer fr ON fr.farmer_id  = cf.farmer_id
JOIN   person p  ON p.national_id = fr.national_id
WHERE  cf.resolution_status IN ('Open','In Progress')
ORDER  BY cf.date_raised;

-- ══════════════════════════════════════════════════════════════════
-- END OF MILESTONE THREE
-- ══════════════════════════════════════════════════════════════════
