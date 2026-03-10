# BDSnowflake

Назначение: лабораторная работа по анализу больших данных. Преобразование исходных данных о зоомагазине в схему «снежинка».

Структура проекта:
- docker-compose.yml — PostgreSQL 15, контейнер petstore_dw, автозагрузка данных
- check.sql — проверка данных
- sql/01_import_mock.sql — создание таблицы mock_data и импорт 10 000 строк из CSV
- sql/02_DDL.sql — создание измерений (dim_*) и таблицы фактов (fact_sales)
- sql/03_DML.sql — заполнение измерений и фактов из mock_data
- sql/04_validation.sql — валидация результата
- data/ — 10 файлов MOCK_DATA_1.csv ... MOCK_DATA_10.csv по 1000 строк

Запуск: docker compose up --build -d

Подключение: host localhost, port 5432, db petstore_analytics, user lab, pass lab123

Таблицы:
- dim_country — страны (country_key, country_name)
- dim_pet_category — категории питомцев (pet_category_key, category_name)
- dim_pet — питомцы (pet_key, pet_type, pet_name, breed, pet_category_key)
- dim_customer — покупатели (customer_key, source_id, first_name, last_name, age, email, postal_code, country_key, pet_key)
- dim_seller — продавцы (seller_key, source_id, first_name, last_name, email, postal_code, country_key)
- dim_product_category — категории товаров (category_key, category_name)
- dim_product_brand — бренды товаров (brand_key, brand_name)
- dim_product — товары (product_key, source_id, product_name, category_key, brand_key, price, weight, color, size, material, description, rating, reviews, release_date, expiry_date)
- dim_store — магазины (store_key, source_id, store_name, location, city, state, country_key, phone, email)
- dim_supplier — поставщики (supplier_key, source_id, supplier_name, contact, email, phone, address, city, country_key)
- dim_date — измерение даты (date_key, full_date, day, month, year, quarter, day_of_week, day_name, month_name, is_weekend)
- fact_sales — продажи (sale_key, source_id, date_key, customer_key, seller_key, product_key, store_key, supplier_key, quantity, unit_price, total_price, sale_date_original)
