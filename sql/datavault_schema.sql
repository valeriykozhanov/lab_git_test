
-- === Схема DV ===
CREATE SCHEMA IF NOT EXISTS dv;

-- Утилита: хеш BK → BYTEA(md5 для краткости)
CREATE OR REPLACE FUNCTION dv.bk_md5(text) RETURNS bytea AS $$
  SELECT decode(md5($1), 'hex');
$$ LANGUAGE sql IMMUTABLE;

-- === HUBS ===
CREATE TABLE IF NOT EXISTS dv.hub_counterparty (
  hk_counterparty   BYTEA PRIMARY KEY,
  bk_counterparty   TEXT  NOT NULL,
  load_dts          TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source     TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_counterparty_bk ON dv.hub_counterparty (bk_counterparty);

CREATE TABLE IF NOT EXISTS dv.hub_product (
  hk_product     BYTEA PRIMARY KEY,
  bk_product     TEXT NOT NULL,
  load_dts       TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source  TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_product_bk ON dv.hub_product (bk_product);

CREATE TABLE IF NOT EXISTS dv.hub_order (
  hk_order       BYTEA PRIMARY KEY,
  bk_order       TEXT NOT NULL,
  load_dts       TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source  TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_order_bk ON dv.hub_order (bk_order);

CREATE TABLE IF NOT EXISTS dv.hub_warehouse (
  hk_warehouse   BYTEA PRIMARY KEY,
  bk_warehouse   TEXT NOT NULL,
  load_dts       TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source  TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_warehouse_bk ON dv.hub_warehouse (bk_warehouse);

CREATE TABLE IF NOT EXISTS dv.hub_route (
  hk_route       BYTEA PRIMARY KEY,
  bk_route       TEXT NOT NULL,
  load_dts       TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source  TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_route_bk ON dv.hub_route (bk_route);

-- === LINKS ===
CREATE TABLE IF NOT EXISTS dv.lnk_order_counterparty (
  hk_l_order_counterparty BYTEA PRIMARY KEY,
  hk_order                BYTEA NOT NULL REFERENCES dv.hub_order(hk_order),
  hk_counterparty         BYTEA NOT NULL REFERENCES dv.hub_counterparty(hk_counterparty),
  load_dts                TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source           TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_lnk_order_counterparty ON dv.lnk_order_counterparty (hk_order, hk_counterparty);

CREATE TABLE IF NOT EXISTS dv.lnk_order_warehouse (
  hk_l_order_warehouse BYTEA PRIMARY KEY,
  hk_order             BYTEA NOT NULL REFERENCES dv.hub_order(hk_order),
  hk_warehouse         BYTEA NOT NULL REFERENCES dv.hub_warehouse(hk_warehouse),
  load_dts             TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source        TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_lnk_order_warehouse ON dv.lnk_order_warehouse (hk_order, hk_warehouse);

CREATE TABLE IF NOT EXISTS dv.lnk_order_route (
  hk_l_order_route BYTEA PRIMARY KEY,
  hk_order         BYTEA NOT NULL REFERENCES dv.hub_order(hk_order),
  hk_route         BYTEA NOT NULL REFERENCES dv.hub_route(hk_route),
  load_dts         TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source    TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_lnk_order_route ON dv.lnk_order_route (hk_order, hk_route);

CREATE TABLE IF NOT EXISTS dv.lnk_order_item (
  hk_l_order_item BYTEA PRIMARY KEY,
  hk_order        BYTEA NOT NULL REFERENCES dv.hub_order(hk_order),
  hk_product      BYTEA NOT NULL REFERENCES dv.hub_product(hk_product),
  load_dts        TIMESTAMPTZ NOT NULL DEFAULT now(),
  record_source   TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_lnk_order_item ON dv.lnk_order_item (hk_order, hk_product);

-- === SATELLITES ===
CREATE TABLE IF NOT EXISTS dv.sat_counterparty (
  hk_counterparty BYTEA NOT NULL REFERENCES dv.hub_counterparty(hk_counterparty),
  load_dts        TIMESTAMPTZ NOT NULL,
  end_dts         TIMESTAMPTZ,
  record_source   TEXT NOT NULL,
  name            TEXT,
  phone           TEXT,
  email           TEXT,
  address         TEXT,
  PRIMARY KEY (hk_counterparty, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_product (
  hk_product      BYTEA NOT NULL REFERENCES dv.hub_product(hk_product),
  load_dts        TIMESTAMPTZ NOT NULL,
  end_dts         TIMESTAMPTZ,
  record_source   TEXT NOT NULL,
  name            TEXT,
  category_name   TEXT,
  unit_of_measure TEXT,
  is_active       BOOLEAN,
  PRIMARY KEY (hk_product, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_order (
  hk_order        BYTEA NOT NULL REFERENCES dv.hub_order(hk_order),
  load_dts        TIMESTAMPTZ NOT NULL,
  end_dts         TIMESTAMPTZ,
  record_source   TEXT NOT NULL,
  status          TEXT,
  requested_date  DATE,
  manager_name    TEXT,
  comment         TEXT,
  PRIMARY KEY (hk_order, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_warehouse (
  hk_warehouse  BYTEA NOT NULL REFERENCES dv.hub_warehouse(hk_warehouse),
  load_dts      TIMESTAMPTZ NOT NULL,
  end_dts       TIMESTAMPTZ,
  record_source TEXT NOT NULL,
  type          TEXT,
  address       TEXT,
  PRIMARY KEY (hk_warehouse, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_route (
  hk_route      BYTEA NOT NULL REFERENCES dv.hub_route(hk_route),
  load_dts      TIMESTAMPTZ NOT NULL,
  end_dts       TIMESTAMPTZ,
  record_source TEXT NOT NULL,
  description   TEXT,
  PRIMARY KEY (hk_route, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_order_item (
  hk_l_order_item BYTEA NOT NULL REFERENCES dv.lnk_order_item(hk_l_order_item),
  load_dts        TIMESTAMPTZ NOT NULL,
  end_dts         TIMESTAMPTZ,
  record_source   TEXT NOT NULL,
  line_no         INT,
  qty             NUMERIC(15,3),
  unit_price      NUMERIC(15,2),
  note            TEXT,
  PRIMARY KEY (hk_l_order_item, load_dts)
);

-- Пример вычисления ключей при загрузке (staging → DV):
-- SELECT dv.bk_md5(order_no)      AS hk_order,
--        dv.bk_md5(sku)           AS hk_product,
--        dv.bk_md5(inn)           AS hk_counterparty,
--        dv.bk_md5(warehouse_nm)  AS hk_warehouse,
--        dv.bk_md5(route_code)    AS hk_route;

