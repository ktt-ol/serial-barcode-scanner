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

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_sells_insert AFTER INSERT ON sells BEGIN
	UPDATE products SET amount = products.amount - 1 WHERE products.id = NEW.product;
END;

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_sells_delete AFTER DELETE ON sells BEGIN
	UPDATE products SET amount = products.amount + 1 WHERE products.id = OLD.product;
END;

CREATE TRIGGER IF NOT EXISTS update_product_amount_on_sells_update AFTER UPDATE ON sells BEGIN
	UPDATE products SET amount = products.amount + 1 WHERE products.id = OLD.product;
	UPDATE products SET amount = products.amount - 1 WHERE products.id = NEW.product;
END;
COMMIT;
