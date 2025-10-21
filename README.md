# Bakery Order DB — 3NF & Data Vault

Учебный проект для лабораторной работы: система приёма заявок на поставку продукции на хлебокомбинате.

## Состав проекта
- `sql/3nf_schema.sql` — операционная схема в **3NF** (PostgreSQL).
- `sql/datavault_schema.sql` — аналитическая схема **Data Vault 2.0** (PostgreSQL).
- `sql/sample_queries.sql` — примеры запросов.
- `docs/lab_report.md` — отчёт к лабораторной (заполните ФИО/группу/вариант).

## Быстрый старm
```bash
# 1) создать БД и подключиться к ней
createdb bakery_db || true
psql -d bakery_db -f sql/3nf_schema.sql
psql -d bakery_db -f sql/datavault_schema.sql

# 2) выполнить примеры запросов
psql -d bakery_db -f sql/sample_queries.sql
```

## Публикация на GitHub
```bash
git init
git add .
git commit -m "Init: 3NF & Data Vault schemas + report"
git branch -M main
git remote add origin https://github.com/<username>/bakery-order-db.git
git push -u origin main
```

> Примечание: редактор Atom снят с поддержки; можно использовать VS Code.
