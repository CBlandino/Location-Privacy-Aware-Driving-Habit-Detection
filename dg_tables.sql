DROP TABLE IF EXISTS Users CASCADE;
CREATE TABLE IF NOT EXISTS Users (
    user_id         SERIAL PRIMARY KEY,        
    first_name      VARCHAR(100) NOT NULL, 
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   BYTEA NOT NULL, 
    salt            BYTEA NOT NULL,
    score           REAL NOT NULL,
);

DROP TABLE IF EXISTS Trips CASCADE;
CREATE TABLE IF NOT EXISTS Trips (
    trip_id         SERIAL PRIMARY KEY,
    user_id         INT NOT NULL,
    start_time      TIMESTAMP NOT NULL,
    done            BOOLEAN NOT NULL,
    data            JSONB NOT NULL,
    distance        REAL NOT NULL, 
    velocity        REAL NOT NULL,
    trip_score      REAL, 
    speed_score     REAL,
    brake_score     REAL, 
    accel_score     REAL, 

    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dg_api') THEN
        CREATE ROLE dg_api WITH LOGIN PASSWORD 'secure';
    ELSE
        RAISE NOTICE 'Role dg_api already exists, skipping.';
    END IF;
END $$;
GRANT CONNECT ON DATABASE dg_db TO dg_api;
GRANT USAGE ON SCHEMA public TO dg_api;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO dg_api;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dg_api;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT ON TABLES TO dg_api;
