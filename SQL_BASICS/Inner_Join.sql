SELECT users.name, addresses.city
FROM users
INNER JOIN addresses ON users.id = addresses.user_id;
