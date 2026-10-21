-- ============================================================================
-- Devnagari PG & Hostel — Initial Database Schema (Flyway V1)
-- Database: PostgreSQL 16+
-- Schema: Fully normalized modular monolith schema with full feature parity
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ============================================================================
-- 1. ORGANIZATION AND CONFIGURATION DOMAIN
-- ============================================================================

CREATE TABLE hostel_settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hostel_name VARCHAR(150) NOT NULL,
    organization_legal_name VARCHAR(200) NOT NULL,
    tagline VARCHAR(255),
    support_email VARCHAR(100),
    support_phone VARCHAR(20),
    receipt_prefix VARCHAR(10) NOT NULL DEFAULT 'DH',
    due_date_rule VARCHAR(30) NOT NULL DEFAULT 'CHECK_IN_DATE' 
        CHECK (due_date_rule IN ('CHECK_IN_DATE', 'FIXED_DAY_OF_MONTH')),
    fixed_due_day INT DEFAULT 1 CHECK (fixed_due_day BETWEEN 1 AND 28),
    grace_period_days INT NOT NULL DEFAULT 5 CHECK (grace_period_days >= 0),
    overdue_charge_type VARCHAR(20) NOT NULL DEFAULT 'FIXED' 
        CHECK (overdue_charge_type IN ('FIXED', 'PER_DAY')),
    overdue_charge_amount NUMERIC(12,2) NOT NULL DEFAULT 200.00 CHECK (overdue_charge_amount >= 0),
    overdue_charge_cap NUMERIC(12,2) DEFAULT NULL,
    notice_period_days INT NOT NULL DEFAULT 30 CHECK (notice_period_days >= 0),
    complaint_reopen_days INT NOT NULL DEFAULT 3 CHECK (complaint_reopen_days >= 0),
    partial_payment_allowed BOOLEAN NOT NULL DEFAULT TRUE,
    auto_apply_credit_balance BOOLEAN NOT NULL DEFAULT TRUE,
    referral_reward_amount NUMERIC(12,2) NOT NULL DEFAULT 500.00 CHECK (referral_reward_amount >= 0),
    razorpay_key_id VARCHAR(100) DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE branches (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    gender_policy VARCHAR(20) NOT NULL CHECK (gender_policy IN ('BOYS', 'GIRLS', 'CO_LIVING')),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL DEFAULT 'Gandhinagar',
    state VARCHAR(100) NOT NULL DEFAULT 'Gujarat',
    postal_code VARCHAR(20) NOT NULL DEFAULT '382007',
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    upi_id VARCHAR(100),
    electricity_rate_per_unit NUMERIC(12,2) NOT NULL DEFAULT 9.00 CHECK (electricity_rate_per_unit >= 0),
    meter_reading_day INT NOT NULL DEFAULT 1 CHECK (meter_reading_day BETWEEN 1 AND 28),
    notice_period_days INT NOT NULL DEFAULT 30 CHECK (notice_period_days >= 0),
    security_deposit_months INT NOT NULL DEFAULT 1 CHECK (security_deposit_months >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE amenities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    code VARCHAR(50) NOT NULL UNIQUE,
    icon_name VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE branch_amenities (
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    amenity_id BIGINT NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
    PRIMARY KEY (branch_id, amenity_id)
);

CREATE TABLE sharing_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE, -- 'SINGLE', '2_SHARING', '3_SHARING', '4_SHARING', '5_SHARING', '6_SHARING'
    name VARCHAR(50) NOT NULL,
    capacity INT NOT NULL CHECK (capacity BETWEEN 1 AND 6)
);

CREATE TABLE room_item_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL, -- 'FURNITURE', 'ELECTRICAL', 'BEDDING', 'KEY'
    is_per_bed BOOLEAN NOT NULL DEFAULT FALSE,
    is_ac_only BOOLEAN NOT NULL DEFAULT FALSE,
    default_quantity INT NOT NULL DEFAULT 1
);

CREATE TABLE cleaning_checklist_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'BEDROOM', 'BATHROOM', 'BALCONY', 'COMMON_AREA'
    description TEXT,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE vendor_categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE message_templates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('WHATSAPP', 'SMS', 'EMAIL')),
    event_trigger VARCHAR(50) NOT NULL,
    subject VARCHAR(200),
    body_template TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inquiry_followup_templates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    step_number INT NOT NULL,
    delay_hours INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    message_text TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE faqs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE branch_help_infos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    warden_name VARCHAR(100),
    warden_phone VARCHAR(20),
    emergency_contact VARCHAR(50),
    gate_closing_time VARCHAR(20),
    wifi_ssid VARCHAR(100),
    wifi_password VARCHAR(100),
    notes TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branch_help UNIQUE (branch_id)
);

CREATE TABLE document_sequences (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id BIGINT REFERENCES branches(id) ON DELETE CASCADE,
    doc_type VARCHAR(30) NOT NULL CHECK (doc_type IN ('RECEIPT', 'CUSTOMER', 'INVOICE', 'SETTLEMENT', 'CASH_BOOK', 'INQUIRY', 'TICKET')),
    financial_year VARCHAR(10) NOT NULL, -- e.g. '26-27'
    current_number BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT uq_doc_seq UNIQUE (branch_id, doc_type, financial_year)
);

-- ============================================================================
-- 2. IDENTITY AND ACCESS DOMAIN
-- ============================================================================

CREATE TABLE staff_users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(30) NOT NULL CHECK (role IN ('ADMIN_OWNER', 'BRANCH_MANAGER', 'FRONT_DESK', 'CLEANING_STAFF')),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE staff_user_branches (
    staff_user_id BIGINT NOT NULL REFERENCES staff_users(id) ON DELETE CASCADE,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    PRIMARY KEY (staff_user_id, branch_id)
);

CREATE TABLE permissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE, -- e.g. 'resident.view', 'payment.discount', 'kyc.verify'
    module VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT
);

CREATE TABLE staff_user_permissions (
    staff_user_id BIGINT NOT NULL REFERENCES staff_users(id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (staff_user_id, permission_id)
);

CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_code VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'DH-CUS-00001'
    full_name VARCHAR(150) NOT NULL,
    mobile VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(150),
    customer_type VARCHAR(30) NOT NULL CHECK (customer_type IN ('STUDENT', 'WORKING_PROFESSIONAL')),
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    dob DATE,
    college_or_company VARCHAR(150),
    permanent_address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    emergency_contact_name VARCHAR(150) NOT NULL,
    emergency_contact_phone VARCHAR(20) NOT NULL,
    emergency_contact_relation VARCHAR(50) NOT NULL,
    photo_file_id VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE otp_challenges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mobile VARCHAR(20) NOT NULL,
    hashed_otp VARCHAR(255) NOT NULL,
    purpose VARCHAR(30) NOT NULL CHECK (purpose IN ('TENANT_LOGIN', 'MOBILE_CHANGE', 'TERMS_VERIFICATION')),
    expires_at TIMESTAMPTZ NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    is_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_otp_mobile_purpose ON otp_challenges (mobile, purpose, is_consumed);

CREATE TABLE auth_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_token_hash VARCHAR(255) NOT NULL UNIQUE,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('STAFF', 'TENANT')),
    staff_user_id BIGINT REFERENCES staff_users(id) ON DELETE CASCADE,
    customer_id BIGINT REFERENCES customers(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_auth_session_target CHECK (
        (user_type = 'STAFF' AND staff_user_id IS NOT NULL AND customer_id IS NULL) OR
        (user_type = 'TENANT' AND customer_id IS NOT NULL AND staff_user_id IS NULL)
    )
);

-- ============================================================================
-- 3. INVENTORY DOMAIN (PROPERTY -> ROOM -> BED)
-- ============================================================================

CREATE TABLE rooms (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    room_number VARCHAR(30) NOT NULL,
    floor INT NOT NULL DEFAULT 1,
    sharing_type_id BIGINT NOT NULL REFERENCES sharing_types(id),
    is_ac BOOLEAN NOT NULL DEFAULT FALSE,
    has_ac_meter BOOLEAN NOT NULL DEFAULT FALSE,
    base_rent_per_bed NUMERIC(12,2) NOT NULL CHECK (base_rent_per_bed >= 0),
    base_deposit_per_bed NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (base_deposit_per_bed >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'MAINTENANCE', 'INACTIVE')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branch_room UNIQUE (branch_id, room_number)
);

CREATE TABLE room_amenities (
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    amenity_id BIGINT NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
    PRIMARY KEY (room_id, amenity_id)
);

CREATE TABLE beds (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    bed_label VARCHAR(10) NOT NULL, -- 'A', 'B', 'C', 'D'
    manual_status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE' 
        CHECK (manual_status IN ('AVAILABLE', 'RESERVED', 'MAINTENANCE')),
    status_remark TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_room_bed UNIQUE (room_id, bed_label)
);

CREATE TABLE bed_reservations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bed_id BIGINT NOT NULL REFERENCES beds(id) ON DELETE RESTRICT,
    customer_name VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    target_move_in_date DATE NOT NULL,
    reserved_until TIMESTAMPTZ NOT NULL,
    token_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00 CHECK (token_amount >= 0),
    token_payment_mode VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'CONVERTED_TO_STAY', 'EXPIRED', 'CANCELLED')),
    notes TEXT,
    created_by BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE room_cleaning_exclusions (
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    checklist_item_id BIGINT NOT NULL REFERENCES cleaning_checklist_items(id) ON DELETE CASCADE,
    PRIMARY KEY (room_id, checklist_item_id)
);

CREATE TABLE inventory_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    bed_id BIGINT REFERENCES beds(id) ON DELETE SET NULL,
    item_type_id BIGINT NOT NULL REFERENCES room_item_types(id),
    identifier VARCHAR(100),
    condition VARCHAR(20) NOT NULL DEFAULT 'GOOD' 
        CHECK (condition IN ('NEW', 'GOOD', 'FAIR', 'DAMAGED', 'MISSING')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory_item_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_item_id BIGINT NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    event_type VARCHAR(30) NOT NULL CHECK (event_type IN ('VERIFIED', 'CONDITION_CHANGED', 'REPLACED', 'REPAIRED')),
    previous_condition VARCHAR(20),
    new_condition VARCHAR(20),
    remarks TEXT,
    recorded_by BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. RESIDENCY LIFECYCLE DOMAIN
-- ============================================================================

CREATE TABLE stays (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stay_code VARCHAR(30) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    initial_branch_id BIGINT NOT NULL REFERENCES branches(id),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'NOTICE_GIVEN', 'CHECKED_OUT', 'TERMINATED')),
    check_in_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_date TIMESTAMPTZ,
    inquiry_id BIGINT, -- Optional reference to converted lead
    created_by BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Partial unique index ensuring at most one active stay per customer
CREATE UNIQUE INDEX uq_customer_active_stay ON stays (customer_id) 
WHERE (status IN ('ACTIVE', 'NOTICE_GIVEN'));

CREATE TABLE bed_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stay_id BIGINT NOT NULL REFERENCES stays(id) ON DELETE RESTRICT,
    bed_id BIGINT NOT NULL REFERENCES beds(id) ON DELETE RESTRICT,
    agreed_monthly_rent NUMERIC(12,2) NOT NULL CHECK (agreed_monthly_rent >= 0),
    agreed_security_deposit NUMERIC(12,2) NOT NULL CHECK (agreed_security_deposit >= 0),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'TRANSFERRED', 'COMPLETED', 'CANCELLED')),
    closure_reason VARCHAR(30) CHECK (closure_reason IN ('TRANSFER', 'CHECKOUT', 'EVICTION', 'ADMIN_ADJUSTMENT')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Concurrency safe bed allocation constraint: no overlapping stays on the same bed
ALTER TABLE bed_allocations 
ADD CONSTRAINT no_overlapping_bed_stays 
EXCLUDE USING gist (
    bed_id WITH =,
    tstzrange(start_date, COALESCE(end_date, 'infinity'::timestamptz)) WITH &&
) WHERE (status = 'ACTIVE');

CREATE TABLE kyc_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    doc_type VARCHAR(30) NOT NULL CHECK (doc_type IN ('AADHAAR', 'PAN', 'PASSPORT', 'VOTER_ID', 'STUDENT_ID', 'EMPLOYEE_ID')),
    masked_document_number VARCHAR(30) NOT NULL, -- e.g. 'XXXX-XXXX-1234'
    front_file_id VARCHAR(255) NOT NULL,
    back_file_id VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' 
        CHECK (status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    remarks TEXT,
    verified_by BIGINT REFERENCES staff_users(id),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE leave_requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    leave_number VARCHAR(30) NOT NULL UNIQUE,
    stay_id BIGINT NOT NULL REFERENCES stays(id) ON DELETE RESTRICT,
    departure_date DATE NOT NULL,
    expected_return_date DATE,
    is_vacating_notice BOOLEAN NOT NULL DEFAULT FALSE,
    reason TEXT NOT NULL,
    emergency_contact_phone VARCHAR(20),
    dues_snapshot_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' 
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    decision_remarks TEXT,
    decided_by BIGINT REFERENCES staff_users(id),
    decided_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE room_transfers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transfer_number VARCHAR(30) NOT NULL UNIQUE,
    stay_id BIGINT NOT NULL REFERENCES stays(id) ON DELETE RESTRICT,
    from_bed_allocation_id BIGINT NOT NULL REFERENCES bed_allocations(id),
    target_bed_id BIGINT NOT NULL REFERENCES beds(id),
    requested_date DATE NOT NULL,
    quote_rent_difference NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    quote_deposit_difference NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    quote_transfer_fee NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    quote_total_payable NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED' 
        CHECK (status IN ('REQUESTED', 'APPROVED', 'PAYMENT_PENDING', 'COMPLETED', 'REJECTED', 'CANCELLED')),
    decision_notes TEXT,
    to_bed_allocation_id BIGINT REFERENCES bed_allocations(id),
    decided_by BIGINT REFERENCES staff_users(id),
    decided_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE check_outs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    settlement_number VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'FS/SEC08B/00001'
    stay_id BIGINT NOT NULL UNIQUE REFERENCES stays(id) ON DELETE RESTRICT,
    checkout_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    final_meter_reading NUMERIC(12,2),
    electricity_dues_settled NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    rental_dues_settled NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_deductions NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    deposit_held_snapshot NUMERIC(12,2) NOT NULL,
    net_refundable_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    refund_status VARCHAR(30) NOT NULL DEFAULT 'REFUND_PENDING' 
        CHECK (refund_status IN ('REFUND_PENDING', 'COLLECTION_PENDING', 'COMPLETED', 'FORFEITED')),
    refund_payment_mode VARCHAR(20),
    refund_transaction_ref VARCHAR(100),
    refunded_at TIMESTAMPTZ,
    approved_by BIGINT REFERENCES staff_users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE check_out_deductions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    check_out_id BIGINT NOT NULL REFERENCES check_outs(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL, -- 'ROOM_DAMAGE', 'KEY_LOSS', 'CLEANING_PENALTY', 'UNPAID_DUES'
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL
);

CREATE TABLE customer_notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    staff_user_id BIGINT NOT NULL REFERENCES staff_users(id),
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE terms_versions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version_label VARCHAR(30) NOT NULL UNIQUE, -- 'v1.0', 'v2.0'
    effective_from DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE terms_sections (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    terms_version_id BIGINT NOT NULL REFERENCES terms_versions(id) ON DELETE CASCADE,
    section_title VARCHAR(150) NOT NULL,
    section_body TEXT NOT NULL,
    display_order INT NOT NULL DEFAULT 0
);

CREATE TABLE terms_acceptances (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    terms_version_id BIGINT NOT NULL REFERENCES terms_versions(id) ON DELETE CASCADE,
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    CONSTRAINT uq_customer_terms UNIQUE (customer_id, terms_version_id)
);

-- ============================================================================
-- 5. BILLING AND MONEY DOMAIN
-- ============================================================================

CREATE TABLE charges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    charge_number VARCHAR(30) NOT NULL UNIQUE,
    stay_id BIGINT NOT NULL REFERENCES stays(id) ON DELETE RESTRICT,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    charge_type VARCHAR(30) NOT NULL 
        CHECK (charge_type IN ('RENT', 'SECURITY_DEPOSIT', 'ELECTRICITY', 'TRANSFER_FEE', 'OVERDUE_CHARGE', 'MAINTENANCE', 'OTHER')),
    billing_period_start DATE,
    billing_period_end DATE,
    due_date DATE NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    description VARCHAR(255),
    is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_charges_stay_due ON charges (stay_id, due_date, is_cancelled);
CREATE INDEX idx_charges_branch ON charges (branch_id, due_date);

CREATE TABLE charge_adjustments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    charge_id BIGINT NOT NULL REFERENCES charges(id) ON DELETE RESTRICT,
    adjustment_type VARCHAR(30) NOT NULL CHECK (adjustment_type IN ('DISCOUNT', 'WAIVER', 'OFFER_CLAIM', 'CREDIT_OFFSET')),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    reason TEXT NOT NULL,
    authorized_by BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_number VARCHAR(50) NOT NULL UNIQUE, -- e.g. 'DH/SEC08B/26-27/00005'
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount > 0),
    payment_mode VARCHAR(20) NOT NULL CHECK (payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'RAZORPAY', 'CREDIT_OFFSET', 'OTHER')),
    transaction_reference VARCHAR(150),
    paid_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    collected_by BIGINT REFERENCES staff_users(id),
    is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    is_transaction_verified BOOLEAN NOT NULL DEFAULT FALSE,
    owner_verification_status VARCHAR(30) NOT NULL DEFAULT 'PENDING_OWNER_VERIFICATION' 
        CHECK (owner_verification_status IN ('NOT_APPLICABLE', 'PENDING_OWNER_VERIFICATION', 'OWNER_VERIFIED', 'FLAGGED')),
    owner_verified_by BIGINT REFERENCES staff_users(id),
    owner_verified_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_payments_customer ON payments (customer_id, paid_at);
CREATE INDEX idx_payments_branch ON payments (branch_id, paid_at);

CREATE TABLE payment_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id BIGINT NOT NULL REFERENCES payments(id) ON DELETE RESTRICT,
    charge_id BIGINT NOT NULL REFERENCES charges(id) ON DELETE RESTRICT,
    allocated_amount NUMERIC(12,2) NOT NULL CHECK (allocated_amount > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_alloc_charge ON payment_allocations (charge_id);
CREATE INDEX idx_alloc_payment ON payment_allocations (payment_id);

CREATE TABLE online_payment_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gateway_order_id VARCHAR(100) NOT NULL UNIQUE, -- Razorpay order_id
    gateway_payment_id VARCHAR(100),
    gateway_signature VARCHAR(255),
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    status VARCHAR(20) NOT NULL DEFAULT 'CREATED' 
        CHECK (status IN ('CREATED', 'PAID', 'FAILED', 'EXPIRED')),
    idempotency_key VARCHAR(100) NOT NULL UNIQUE,
    resulting_payment_id BIGINT REFERENCES payments(id),
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE online_payment_order_charges (
    order_id BIGINT NOT NULL REFERENCES online_payment_orders(id) ON DELETE CASCADE,
    charge_id BIGINT NOT NULL REFERENCES charges(id) ON DELETE RESTRICT,
    allocated_amount NUMERIC(12,2) NOT NULL CHECK (allocated_amount > 0),
    PRIMARY KEY (order_id, charge_id)
);

CREATE TABLE pay_links (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token VARCHAR(64) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customer_credit_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    entry_type VARCHAR(30) NOT NULL CHECK (entry_type IN ('CREDIT', 'DEBIT')),
    source_type VARCHAR(30) NOT NULL CHECK (source_type IN ('OVERPAYMENT', 'TRANSFER_CREDIT', 'REFERRAL_REWARD', 'ADJUSTMENT')),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    reference_id VARCHAR(100),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE meter_readings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
    reading_type VARCHAR(20) NOT NULL CHECK (reading_type IN ('START', 'MONTHLY', 'FINAL', 'TRANSFER')),
    reading_value NUMERIC(12,2) NOT NULL CHECK (reading_value >= 0),
    rate_snapshot NUMERIC(12,2) NOT NULL CHECK (rate_snapshot >= 0),
    reading_date DATE NOT NULL,
    photo_file_id VARCHAR(255),
    recorded_by BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE electricity_shares (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
    stay_id BIGINT NOT NULL REFERENCES stays(id) ON DELETE RESTRICT,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    resident_count INT NOT NULL CHECK (resident_count > 0),
    total_units_consumed NUMERIC(12,2) NOT NULL CHECK (total_units_consumed >= 0),
    resident_share_units NUMERIC(12,2) NOT NULL CHECK (resident_share_units >= 0),
    resident_share_amount NUMERIC(12,2) NOT NULL CHECK (resident_share_amount >= 0),
    charge_id BIGINT REFERENCES charges(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cash_book_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    receipt_book_number VARCHAR(50) NOT NULL, -- e.g. 'CR-00125'
    entry_type VARCHAR(20) NOT NULL CHECK (entry_type IN ('COLLECTION', 'PETTY_EXPENSE', 'MANUAL_ENTRY')),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_id BIGINT REFERENCES payments(id),
    description TEXT NOT NULL,
    recorded_by BIGINT NOT NULL REFERENCES staff_users(id),
    owner_verified BOOLEAN NOT NULL DEFAULT FALSE,
    owner_verified_by BIGINT REFERENCES staff_users(id),
    entry_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE offers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('FLAT', 'PERCENT')),
    discount_value NUMERIC(12,2) NOT NULL CHECK (discount_value > 0),
    max_discount_cap NUMERIC(12,2),
    min_stay_months INT NOT NULL DEFAULT 1,
    valid_from DATE NOT NULL,
    valid_until DATE NOT NULL,
    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC' CHECK (visibility IN ('PUBLIC', 'CODE_ONLY')),
    total_claim_limit INT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE offer_branches (
    offer_id BIGINT NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    PRIMARY KEY (offer_id, branch_id)
);

CREATE TABLE offer_claims (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offer_id BIGINT NOT NULL REFERENCES offers(id) ON DELETE RESTRICT,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    stay_id BIGINT NOT NULL REFERENCES stays(id) ON DELETE RESTRICT,
    charge_id BIGINT REFERENCES charges(id),
    discount_applied NUMERIC(12,2) NOT NULL CHECK (discount_applied > 0),
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_offer_customer UNIQUE (offer_id, customer_id)
);

CREATE TABLE referrals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    referrer_customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    referee_name VARCHAR(150) NOT NULL,
    referee_phone VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING' 
        CHECK (status IN ('PENDING', 'ELIGIBLE', 'REWARD_APPROVED', 'REWARD_CREDITED', 'REJECTED')),
    converted_stay_id BIGINT REFERENCES stays(id),
    reward_amount NUMERIC(12,2) NOT NULL DEFAULT 500.00,
    credit_entry_id BIGINT REFERENCES customer_credit_entries(id),
    approved_by BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 6. OPERATIONS DOMAIN
-- ============================================================================

CREATE TABLE complaints (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_number VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'CMP-00042'
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    stay_id BIGINT REFERENCES stays(id) ON DELETE SET NULL,
    room_id BIGINT REFERENCES rooms(id) ON DELETE SET NULL,
    category VARCHAR(50) NOT NULL, -- 'PLUMBING', 'ELECTRICAL', 'WIFI', 'CLEANING', 'FURNITURE', 'OTHER'
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'EMERGENCY')),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' 
        CHECK (status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REOPENED')),
    assigned_staff_user_id BIGINT REFERENCES staff_users(id),
    external_technician_name VARCHAR(100),
    external_technician_phone VARCHAR(20),
    resolution_notes TEXT,
    resolved_by BIGINT REFERENCES staff_users(id),
    resolved_at TIMESTAMPTZ,
    reopen_deadline TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE complaint_photos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    file_id VARCHAR(255) NOT NULL,
    caption VARCHAR(255),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE complaint_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    event_type VARCHAR(30) NOT NULL CHECK (event_type IN ('CREATED', 'ASSIGNED', 'STATUS_CHANGE', 'REOPENED', 'RESOLVED', 'CLOSED')),
    actor_user_id BIGINT REFERENCES staff_users(id),
    actor_customer_id BIGINT REFERENCES customers(id),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cleaning_records (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
    cleaning_date DATE NOT NULL,
    staff_user_id BIGINT NOT NULL REFERENCES staff_users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'SKIPPED')),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_room_cleaning_date UNIQUE (room_id, cleaning_date)
);

CREATE TABLE cleaning_record_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cleaning_record_id BIGINT NOT NULL REFERENCES cleaning_records(id) ON DELETE CASCADE,
    checklist_item_id BIGINT NOT NULL REFERENCES cleaning_checklist_items(id) ON DELETE RESTRICT,
    is_cleaned BOOLEAN NOT NULL DEFAULT TRUE,
    remarks TEXT
);

CREATE TABLE cleaning_verifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cleaning_record_id BIGINT NOT NULL REFERENCES cleaning_records(id) ON DELETE CASCADE,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    result VARCHAR(20) NOT NULL CHECK (result IN ('OK', 'NOT_CLEAN')),
    remarks TEXT,
    auto_created_complaint_id BIGINT REFERENCES complaints(id),
    verified_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cleaning_verification UNIQUE (cleaning_record_id, customer_id)
);

CREATE TABLE vendors (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vendor_category_id BIGINT NOT NULL REFERENCES vendor_categories(id),
    name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    gst_number VARCHAR(30),
    bank_account_details TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expenses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    vendor_id BIGINT REFERENCES vendors(id) ON DELETE SET NULL,
    category VARCHAR(50) NOT NULL, -- 'GROCERY', 'ELECTRICITY_BILL', 'PLUMBING_MAINTENANCE', 'WIFI', 'SALARY', 'OTHER'
    title VARCHAR(200) NOT NULL,
    invoice_number VARCHAR(100),
    invoice_date DATE,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount > 0),
    description TEXT,
    receipt_file_id VARCHAR(255),
    recorded_by BIGINT NOT NULL REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expense_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    expense_id BIGINT NOT NULL REFERENCES expenses(id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_mode VARCHAR(20) NOT NULL CHECK (payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'OTHER')),
    transaction_reference VARCHAR(150),
    paid_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_by BIGINT NOT NULL REFERENCES staff_users(id),
    notes TEXT
);

-- ============================================================================
-- 7. CRM AND LEADS DOMAIN
-- ============================================================================

CREATE TABLE inquiries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inquiry_number VARCHAR(30) NOT NULL UNIQUE, -- e.g. 'INQ-00006'
    branch_id BIGINT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    source VARCHAR(30) NOT NULL CHECK (source IN ('WALK_IN', 'WHATSAPP', 'WEBSITE', 'REFERENCE', 'JUSTDIAL', 'OTHER')),
    sharing_type_preference_id BIGINT REFERENCES sharing_types(id),
    is_ac_preference BOOLEAN DEFAULT FALSE,
    budget_max NUMERIC(12,2),
    target_move_in_date DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'NEW' 
        CHECK (status IN ('NEW', 'FOLLOW_UP', 'VISIT_SCHEDULED', 'VISIT_COMPLETED', 'BOOKED', 'LOST')),
    scheduled_next_action VARCHAR(50),
    next_follow_up_at TIMESTAMPTZ,
    converted_customer_id BIGINT REFERENCES customers(id),
    assigned_staff_user_id BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inquiry_notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inquiry_id BIGINT NOT NULL REFERENCES inquiries(id) ON DELETE CASCADE,
    staff_user_id BIGINT NOT NULL REFERENCES staff_users(id),
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE room_links (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token VARCHAR(64) NOT NULL UNIQUE,
    inquiry_id BIGINT REFERENCES inquiries(id) ON DELETE SET NULL,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE room_link_rooms (
    room_link_id BIGINT NOT NULL REFERENCES room_links(id) ON DELETE CASCADE,
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    PRIMARY KEY (room_link_id, room_id)
);

CREATE TABLE outbound_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('WHATSAPP', 'SMS', 'EMAIL')),
    recipient VARCHAR(100) NOT NULL,
    message_type VARCHAR(50) NOT NULL, -- 'RECEIPT', 'PAYMENT_REMINDER', 'INQUIRY_FOLLOWUP', 'ROOM_LINK'
    reference_entity_type VARCHAR(50),
    reference_entity_id BIGINT,
    message_content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED' 
        CHECK (status IN ('SCHEDULED', 'SENT', 'FAILED', 'SKIPPED')),
    error_message TEXT,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 8. COMMUNICATION AND AUDIT DOMAIN
-- ============================================================================

CREATE TABLE announcements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL' CHECK (priority IN ('NORMAL', 'IMPORTANT', 'URGENT')),
    target_scope VARCHAR(20) NOT NULL CHECK (target_scope IN ('ALL', 'BRANCH', 'ROOMS', 'INDIVIDUALS')),
    branch_id BIGINT REFERENCES branches(id),
    created_by BIGINT NOT NULL REFERENCES staff_users(id),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE announcement_targets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    room_id BIGINT REFERENCES rooms(id) ON DELETE CASCADE,
    customer_id BIGINT REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE customer_notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'BILLING', 'LEAVE', 'COMPLAINT', 'GENERAL', 'ANNOUNCEMENT'
    action_url VARCHAR(255),
    dedupe_key VARCHAR(100) UNIQUE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_cust_notif_read ON customer_notifications (customer_id, is_read);

CREATE TABLE staff_notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id BIGINT REFERENCES branches(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    action_url VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE staff_notification_reads (
    staff_notification_id BIGINT NOT NULL REFERENCES staff_notifications(id) ON DELETE CASCADE,
    staff_user_id BIGINT NOT NULL REFERENCES staff_users(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (staff_notification_id, staff_user_id)
);

CREATE TABLE activity_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id BIGINT REFERENCES branches(id) ON DELETE SET NULL,
    actor_type VARCHAR(20) NOT NULL CHECK (actor_type IN ('STAFF', 'TENANT', 'SYSTEM')),
    actor_staff_user_id BIGINT REFERENCES staff_users(id) ON DELETE SET NULL,
    actor_customer_id BIGINT REFERENCES customers(id) ON DELETE SET NULL,
    action_type VARCHAR(100) NOT NULL, -- 'RESIDENT_CHECKIN', 'PAYMENT_COLLECTED', 'TRANSFER_COMPLETED'
    entity_name VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    details_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_activity_branch ON activity_logs (branch_id, created_at);

CREATE TABLE stored_files (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    file_uuid VARCHAR(64) NOT NULL UNIQUE,
    original_filename VARCHAR(255) NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'KYC', 'COMPLAINT_PHOTO', 'METER_PHOTO', 'RECEIPT_PDF'
    uploaded_by_user_id BIGINT REFERENCES staff_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
