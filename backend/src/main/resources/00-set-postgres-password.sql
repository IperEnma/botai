-- Fija la contraseña del usuario postgres (se ejecuta primero por el prefijo 00-).
-- Necesario para que la app desde el host pueda conectar con postgres/postgres.
ALTER USER postgres WITH PASSWORD 'postgres';
