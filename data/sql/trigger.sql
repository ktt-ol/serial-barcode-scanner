BEGIN TRANSACTION;
CREATE TRIGGER IF NOT EXISTS update_product_amount_on_restock_insert AFTER INSERT ON restock BEGIN
	UPDATE products SET amount = products.amount + NEW.amount WHERE products.id = NEW.product;
END;

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_restock_delete AFTER DELETE ON restock BEGIN
	UPDATE products SET amount = products.amount - OLD.amount WHERE products.id = OLD.product;
END;

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_restock_update AFTER UPDATE ON restock BEGIN
	UPDATE products SET amount = products.amount - OLD.amount WHERE products.id = OLD.product;
	UPDATE products SET amount = products.amount + NEW.amount WHERE products.id = NEW.product;
END;

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_sales_insert AFTER INSERT ON sales BEGIN
	UPDATE products SET amount = products.amount - 1 WHERE products.id = NEW.product;
END;

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_sales_delete AFTER DELETE ON sales BEGIN
	UPDATE products SET amount = products.amount + 1 WHERE products.id = OLD.product;
END;

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_sales_update AFTER UPDATE ON sales BEGIN
	UPDATE products SET amount = products.amount + 1 WHERE products.id = OLD.product;
	UPDATE products SET amount = products.amount - 1 WHERE products.id = NEW.product;
END;
COMMIT;
