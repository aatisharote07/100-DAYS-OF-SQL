USE startersql;
 SELECT users.name, addresses.city
 FROM users
 RIGHT JOIN addresses ON users.id = addresses.user_id;