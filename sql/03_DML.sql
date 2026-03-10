-- ШАГ 1: Справочники

-- Страны (сбор из всех сущностей)
INSERT INTO dim_country (country_name)
SELECT DISTINCT TRIM(val) FROM (
    SELECT customer_country AS val FROM mock_data WHERE customer_country IS NOT NULL AND customer_country != ''
    UNION
    SELECT seller_country FROM mock_data WHERE seller_country IS NOT NULL AND seller_country != ''
    UNION
    SELECT store_country FROM mock_data WHERE store_country IS NOT NULL AND store_country != ''
    UNION
    SELECT supplier_country FROM mock_data WHERE supplier_country IS NOT NULL AND supplier_country != ''
) AS countries
ON CONFLICT (country_name) DO NOTHING;

-- Категория питомца
INSERT INTO dim_pet_category (category_name)
SELECT DISTINCT TRIM(pet_category) 
FROM mock_data 
WHERE pet_category IS NOT NULL AND pet_category != ''
ON CONFLICT (category_name) DO NOTHING;

-- Питомцы (уникальные комбинации)
INSERT INTO dim_pet (pet_type, pet_name, breed, pet_category_key)
SELECT DISTINCT
    TRIM(md.customer_pet_type),
    TRIM(md.customer_pet_name),
    TRIM(md.customer_pet_breed),
    pc.pet_category_key
FROM mock_data md
LEFT JOIN dim_pet_category pc 
    ON TRIM(md.pet_category) = pc.category_name
WHERE md.customer_pet_type IS NOT NULL 
  AND md.customer_pet_type != ''
ON CONFLICT (pet_type, pet_name, breed) DO NOTHING;

-- Покупатели
INSERT INTO dim_customer (
    source_id, first_name, last_name, age, email, postal_code, 
    country_key, pet_key
)
SELECT DISTINCT
    md.id,
    TRIM(md.customer_first_name),
    TRIM(md.customer_last_name),
    md.customer_age,
    TRIM(md.customer_email),
    TRIM(md.customer_postal_code),
    c.country_key,
    p.pet_key
FROM mock_data md
LEFT JOIN dim_country c 
    ON TRIM(md.customer_country) = c.country_name
LEFT JOIN dim_pet p 
    ON TRIM(md.customer_pet_type) = p.pet_type 
    AND TRIM(md.customer_pet_name) = p.pet_name 
    AND TRIM(md.customer_pet_breed) = p.breed
WHERE md.customer_first_name IS NOT NULL
ON CONFLICT (source_id) DO NOTHING;

-- Продавцы
INSERT INTO dim_seller (
    source_id, first_name, last_name, email, postal_code, country_key
)
SELECT DISTINCT
    md.sale_seller_id,
    TRIM(md.seller_first_name),
    TRIM(md.seller_last_name),
    TRIM(md.seller_email),
    TRIM(md.seller_postal_code),
    c.country_key
FROM mock_data md
LEFT JOIN dim_country c 
    ON TRIM(md.seller_country) = c.country_name
WHERE md.seller_first_name IS NOT NULL
ON CONFLICT (source_id) DO NOTHING;

-- Справочники товара
INSERT INTO dim_product_category (category_name)
SELECT DISTINCT TRIM(product_category) 
FROM mock_data 
WHERE product_category IS NOT NULL AND product_category != ''
ON CONFLICT (category_name) DO NOTHING;

INSERT INTO dim_product_brand (brand_name)
SELECT DISTINCT TRIM(product_brand) 
FROM mock_data 
WHERE product_brand IS NOT NULL AND product_brand != ''
ON CONFLICT (brand_name) DO NOTHING;

-- Товары
INSERT INTO dim_product (
    source_id, product_name, category_key, brand_key,
    price, weight, color, size, material, description,
    rating, reviews, release_date, expiry_date
)
SELECT DISTINCT
    md.sale_product_id,
    TRIM(md.product_name),
    pc.category_key,
    pb.brand_key,
    md.product_price,
    md.product_weight,
    TRIM(md.product_color),
    TRIM(md.product_size),
    TRIM(md.product_material),
    TRIM(md.product_description),
    md.product_rating,
    md.product_reviews,
    CASE 
        WHEN md.product_release_date ~ '^\d{1,2}/\d{1,2}/\d{4}$' 
        THEN TO_DATE(md.product_release_date, 'MM/DD/YYYY')
        ELSE NULL 
    END,
    CASE 
        WHEN md.product_expiry_date ~ '^\d{1,2}/\d{1,2}/\d{4}$' 
        THEN TO_DATE(md.product_expiry_date, 'MM/DD/YYYY')
        ELSE NULL 
    END
FROM mock_data md
LEFT JOIN dim_product_category pc 
    ON TRIM(md.product_category) = pc.category_name
LEFT JOIN dim_product_brand pb 
    ON TRIM(md.product_brand) = pb.brand_name
WHERE md.product_name IS NOT NULL
ON CONFLICT (source_id) DO NOTHING;

-- Магазины (генерируем source_id, т.к. нет явного)
INSERT INTO dim_store (
    source_id, store_name, location, city, state, country_key, phone, email
)
SELECT DISTINCT
    DENSE_RANK() OVER (ORDER BY md.store_name, md.store_city),
    TRIM(md.store_name),
    TRIM(md.store_location),
    TRIM(md.store_city),
    TRIM(md.store_state),
    c.country_key,
    TRIM(md.store_phone),
    TRIM(md.store_email)
FROM mock_data md
LEFT JOIN dim_country c 
    ON TRIM(md.store_country) = c.country_name
WHERE md.store_name IS NOT NULL
ON CONFLICT (source_id) DO NOTHING;

-- Поставщики 
INSERT INTO dim_supplier (
    source_id, supplier_name, contact, email, phone, address, city, country_key
)
SELECT DISTINCT
    DENSE_RANK() OVER (ORDER BY md.supplier_name),
    TRIM(md.supplier_name),
    TRIM(md.supplier_contact),
    TRIM(md.supplier_email),
    TRIM(md.supplier_phone),
    TRIM(md.supplier_address),
    TRIM(md.supplier_city),
    c.country_key
FROM mock_data md
LEFT JOIN dim_country c 
    ON TRIM(md.supplier_country) = c.country_name
WHERE md.supplier_name IS NOT NULL
ON CONFLICT (source_id) DO NOTHING;

-- Дата 
-- Добавляем колонку для конвертированной даты
ALTER TABLE mock_data 
ADD COLUMN IF NOT EXISTS sale_date_converted DATE;

-- Конвертируем даты 
UPDATE mock_data SET
    sale_date_converted = TO_DATE(sale_date, 'MM/DD/YYYY')
WHERE sale_date IS NOT NULL 
  AND sale_date != ''
  AND sale_date ~ '^\d{1,2}/\d{1,2}/\d{4}$';

-- Заполняем dim_date
INSERT INTO dim_date (date_key, full_date, day, month, year, quarter, day_of_week, day_name, month_name, is_weekend)
SELECT DISTINCT
    EXTRACT(YEAR FROM sale_date_converted)::INTEGER * 10000 + 
    EXTRACT(MONTH FROM sale_date_converted)::INTEGER * 100 + 
    EXTRACT(DAY FROM sale_date_converted)::INTEGER,
    sale_date_converted,
    EXTRACT(DAY FROM sale_date_converted)::INTEGER,
    EXTRACT(MONTH FROM sale_date_converted)::INTEGER,
    EXTRACT(YEAR FROM sale_date_converted)::INTEGER,
    EXTRACT(QUARTER FROM sale_date_converted)::INTEGER,
    EXTRACT(DOW FROM sale_date_converted)::INTEGER,
    TO_CHAR(sale_date_converted, 'Day'),
    TO_CHAR(sale_date_converted, 'Month'),
    EXTRACT(DOW FROM sale_date_converted) IN (0,6)
FROM mock_data
WHERE sale_date_converted IS NOT NULL
ON CONFLICT (date_key) DO NOTHING;

-- факт продаж
INSERT INTO fact_sales (
    source_id, date_key, customer_key, seller_key,
    product_key, store_key, supplier_key,
    quantity, unit_price, total_price, sale_date_original
)
SELECT
    md.id,
    d.date_key,
    c.customer_key,
    s.seller_key,
    p.product_key,
    st.store_key,
    sup.supplier_key,
    md.sale_quantity,
    md.product_price,
    md.sale_total_price,
    md.sale_date_converted
FROM mock_data md
LEFT JOIN dim_date d 
    ON d.full_date = md.sale_date_converted
LEFT JOIN dim_customer c 
    ON c.source_id = md.sale_customer_id
LEFT JOIN dim_seller s 
    ON s.source_id = md.sale_seller_id
LEFT JOIN dim_product p 
    ON p.source_id = md.sale_product_id
LEFT JOIN dim_store st 
    ON st.store_name = TRIM(md.store_name) 
    AND st.city = TRIM(md.store_city)
LEFT JOIN dim_supplier sup 
    ON sup.supplier_name = TRIM(md.supplier_name);


SELECT ' Fact sales: ' || COUNT(*) AS status FROM fact_sales
UNION ALL
SELECT ' Customers: ' || COUNT(*) FROM dim_customer
UNION ALL
SELECT ' Products: ' || COUNT(*) FROM dim_product
UNION ALL
SELECT ' Dates: ' || COUNT(*) FROM dim_date;