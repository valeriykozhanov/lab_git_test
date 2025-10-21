
-- === Схема 3NF ===
CREATE SCHEMA IF NOT EXISTS ops;

-- === Справочники===
CREATE TABLE IF NOT EXISTS ops.counterparty (
  counterparty_id   BIGSERIAL PRIMARY KEY,
  name              TEXT NOT NULL,
  inn               TEXT,
  kpp               TEXT,
  phone             TEXT,
  email             TEXT,
  address           TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS ops.product_category (
  category_id   BIGSERIAL PRIMARY KEY,
  name          TEXT NOT NULL UNIQUE,
  description   TEXT
);

CREATE TABLE IF NOT EXISTS ops.product (
  product_id      BIGSERIAL PRIMARY KEY,
  sku             TEXT NOT NULL UNIQUE,
  name            TEXT NOT NULL,
  category_id     BIGINT NOT NULL REFERENCES ops.product_category(category_id),
  unit_of_measure TEXT NOT NULL DEFAULT 'шт',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ops.warehouse (
  warehouse_id BIGSERIAL PRIMARY KEY,
  name         TEXT NOT NULL UNIQUE,
  type         TEXT NOT NULL DEFAULT 'СКЛАД',
  address      TEXT
);

CREATE TABLE IF NOT EXISTS ops.employee (
  employee_id BIGSERIAL PRIMARY KEY,
  full_name   TEXT NOT NULL,
  role        TEXT NOT NULL DEFAULT 'manager',
  email       TEXT,
  phone       TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS ops.route (
  route_id    BIGSERIAL PRIMARY KEY,
  code        TEXT NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE IF NOT EXISTS ops.payment_term (
  payment_term_id BIGSERIAL PRIMARY KEY,
  name            TEXT NOT NULL UNIQUE,
  days_due        INT NOT NULL DEFAULT 0
);

-- === Заказы (заявки) ===
CREATE TABLE IF NOT EXISTS ops."order" (
  order_id         BIGSERIAL PRIMARY KEY,
  order_no         TEXT NOT NULL UNIQUE,
  counterparty_id  BIGINT NOT NULL REFERENCES ops.counterparty(counterparty_id),
  warehouse_id     BIGINT REFERENCES ops.warehouse(warehouse_id),
  route_id         BIGINT REFERENCES ops.route(route_id),
  manager_id       BIGINT REFERENCES ops.employee(employee_id),
  requested_date   DATE,
  status           TEXT NOT NULL DEFAULT 'NEW',
  comment          TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_counterparty ON ops."order"(counterparty_id);
CREATE INDEX IF NOT EXISTS idx_order_status ON ops."order"(status);
CREATE INDEX IF NOT EXISTS idx_order_requested_date ON ops."order"(requested_date);

CREATE TABLE IF NOT EXISTS ops.order_item (
  order_id     BIGINT NOT NULL REFERENCES ops."order"(order_id) ON DELETE CASCADE,
  line_no      INT    NOT NULL,
  product_id   BIGINT NOT NULL REFERENCES ops.product(product_id),
  qty          NUMERIC(15,3) NOT NULL CHECK (qty > 0),
  unit_price   NUMERIC(15,2) NOT NULL CHECK (unit_price >= 0),
  note         TEXT,
  PRIMARY KEY (order_id, line_no)
);

CREATE INDEX IF NOT EXISTS idx_order_item_product ON ops.order_item(product_id);

CREATE TABLE IF NOT EXISTS ops.order_status_history (
  status_history_id BIGSERIAL PRIMARY KEY,
  order_id          BIGINT NOT NULL REFERENCES ops."order"(order_id) ON DELETE CASCADE,
  status            TEXT   NOT NULL,
  changed_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  changed_by        BIGINT REFERENCES ops.employee(employee_id),
  remark            TEXT
);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order ON ops.order_status_history(order_id);

CREATE TABLE IF NOT EXISTS ops.order_payment (
  order_id         BIGINT PRIMARY KEY REFERENCES ops."order"(order_id) ON DELETE CASCADE,
  payment_term_id  BIGINT NOT NULL REFERENCES ops.payment_term(payment_term_id),
  prepayment_pct   NUMERIC(5,2) CHECK (prepayment_pct BETWEEN 0 AND 100),
  amount_expected  NUMERIC(15,2),
  currency         TEXT NOT NULL DEFAULT 'RUB',
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- === Бизнес‑правило: нельзя отгрузить пустую заявку ===
CREATE OR REPLACE FUNCTION ops.check_can_ship() RETURNS trigger AS $$
BEGIN
  IF NEW.status = 'SHIPPED' THEN
    PERFORM 1 FROM ops.order_item WHERE order_id = NEW.order_id LIMIT 1;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Нельзя отгрузить пустую заявку %', NEW.order_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_order_ship_guard ON ops."order";
CREATE TRIGGER trg_order_ship_guard
BEFORE UPDATE OF status ON ops."order"
FOR EACH ROW
EXECUTE FUNCTION ops.check_can_ship();

