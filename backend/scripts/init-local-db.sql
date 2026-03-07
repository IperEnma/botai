-- Run as superuser (e.g. postgres): psql -U postgres -f scripts/init-local-db.sql
-- Creates user and database to match application.yml defaults.

CREATE USER chatbot WITH PASSWORD 'chatbot';
CREATE DATABASE chatbot OWNER chatbot;

-- Grant privileges (optional, for cross-db or extensions)
\c chatbot
GRANT ALL PRIVILEGES ON SCHEMA public TO chatbot;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO chatbot;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO chatbot;
