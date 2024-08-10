CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    address VARCHAR(255)
);

-- Создание таблицы orders
CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    shipping_address VARCHAR(255),
    order_status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- Создание таблицы product_categories
CREATE TABLE IF NOT EXISTS product_categories (
    category_id SERIAL PRIMARY KEY,
  	category_name VARCHAR(50)
);

-- Создание таблицы products
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    stock INT,
    price NUMERIC(10, 2),
  	category_id INT,
    description TEXT,
    product_name VARCHAR(100),
  	FOREIGN KEY (category_id) REFERENCES product_categories(category_id) ON DELETE CASCADE
);

-- Создание таблицы order_details
CREATE TABLE IF NOT EXISTS order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price NUMERIC(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);


-- Вставка данных в таблицу customers
INSERT INTO customers (first_name, last_name, email, phone, address)
VALUES
('John', 'Doe', 'john.doe@example.com', '123-456-7890', '123 Elm St'),
('Jane', 'Doe', 'jane.doe@example.com', '987-654-3210', '456 Oak St'),
('Alice', 'Johnson', 'alice.johnson@example.com', '555-678-1234', '789 Pine St'),
('Bob', 'Smith', 'bob.smith@example.com', '555-123-4567', '789 Maple St'),
('Charlie', 'Brown', 'charlie.brown@example.com', '555-987-6543', '321 Chestnut St');

-- Вставка данных в таблицу orders
INSERT INTO orders (customer_id, order_date, shipping_address, order_status)
VALUES
(1, '2023-01-01', '123 Elm St', 'Shipped'),
(2, '2023-01-02', '456 Oak St', 'Pending'),
(3, '2023-01-03', '789 Pine St', 'Delivered'),
(4, '2023-01-04', '789 Maple St', 'Cancelled'),
(5, '2023-01-05', '321 Chestnut St', 'Shipped');



-- Проверка вставки данных в таблицу customers
SELECT * FROM customers;

-- Проверка связей FOREIGN KEY
SELECT orders.order_id, orders.order_date, orders.shipping_address, orders.order_status, customers.first_name, customers.last_name
FROM orders
JOIN customers ON orders.customer_id = customers.customer_id;


-- Проверка вставки данных в таблицу orders
select * from orders;


-- Вставка данных в таблицу product_categories
INSERT INTO product_categories (category_name)
VALUES
('Household chemicals'),
('Stationery'),
('Beverages'),
('Food'),
('Clotht');


-- Вставка данных в таблицу products
INSERT INTO products (stock, price, category_id, description, product_name)
VALUES
(10, 40.56, 5, 'Thick-soled leather running shoes high quality', 'Sneakers for men'),
(10, 5, 5, 'T-shirt, 100% cotton high quality, L size', 'Nike shirt'),
(10, 3.36, 4, 'Italian bred from tascana with cheese ant tomatous big size', 'Pizza_italiano'),
(10, 2.36, 3, 'Milk 2.5% fat in a two-liter tetra pack', 'Milk 2.0 l'),
(10, 5.60, 4, 'Finnish salami of the highest category from reindeer meat, 0.5 kg.', 'Salami finn 0.5 kg.'),
(10, 2.59, 1, 'FAIRY Lemon Flavor Dishwashing Liquid 900 mill.', 'Fairy'),
(10, 12.99, 1, 'Laundry Detergent Gel Universal PERSIL 5L', 'Persil 5l'),
(10, 1.36, 3, 'Natural mineral water VENDEN, 1,5 l, carbonated or still', 'VENDEN, 1,5l'),
(10, 3.26, 2, 'Penal with stationery, 1 pc., various designs', 'Penal'),
(10, 4.00, 2, 'Plastic stapler #10 on 12sheet. FOROFIS with metal movement (red)', 'Stapler'),
(10, 1.99, 4, 'Eggs, 10 pcs, grade A, size L, from a farm with natural chicken nutrition', 'Eggs 10 pcs');


-- Вставка данных в таблицу order_details
INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES
(1, 1, 2, 40.56),
(2, 2, 2, 5),
(3, 3, 1, 3.36),
(4, 4, 3, 2.36),
(5, 5, 2, 5.60);


-- Создание функции для получения общей суммы продаж по категориям товаров за определенный период
CREATE FUNCTION get_orders_sum_by_categories_for_date_interval(date_from DATE, date_for DATE) 
RETURNS TABLE (
  total NUMERIC(10, 2), categoria VARCHAR(50)
)
AS $$
BEGIN
  RETURN QUERY
    SELECT SUM(quantity * unit_price), cat.category_name
    FROM order_details as od
    inner Join orders as ord on od.order_id = ord.order_id
    inner join products as pr on od.product_id = pr.product_id
    inner join product_categories as cat on pr.category_id = cat.category_id
    WHERE ord.order_date >= date_from  AND ord.order_date <= date_for
    group by cat.category_id;
END;
$$ LANGUAGE plpgsql;


-- Запуск функции для получения общей суммы продаж по категориям товаров за определенный период
SELECT get_orders_sum_by_categories_for_date_interval(DATE('2023-01-01'), DATE('2024-01-01'));

-- Создание процедуры для обновления количества товара на складе после создания нового заказа
CREATE PROCEDURE update_stock(orderid INT)
AS $$
BEGIN
  UPDATE products 
  SET stock = stock - 
  (
  select order_details.quantity from order_details
  WHERE order_details.order_id = orderid
  )
  WHERE product_id = (
  select od.product_id from order_details As od
  WHERE od.order_id = orderid
  );
exception 
       	when undefined_column then
       	RAISE NOTICE 'Код ошибки: %', SQLSTATE;
       	RAISE;
       	WHEN OTHERS THEN
		RAISE NOTICE 'Код ошибки: %', SQLSTATE;
		RAISE NOTICE 'Причина ошибки: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


-- Запуск прцедуры для обновления количества товара на складе после создания нового заказа
CALL update_stock(300);
select * from products;

