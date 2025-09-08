USE my_Firstdb;
RENAME TABLE users to customers;	
ALTER TABLE customers ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE customers DROP COLUMN is_active;
RENAME TABLE customers to users;