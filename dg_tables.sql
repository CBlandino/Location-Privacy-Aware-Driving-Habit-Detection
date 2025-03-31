DROP TABLE IF EXISTS Users;
CREATE TABLE Users (
    user_id         SERIAL PRIMARY KEY,        
    first_name      VARCHAR(100) NOT NULL, 
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   BYTEA NOT NULL, 
    salt            BYTEA NOT NULL
);

DROP TABLE IF EXISTS Trips;
CREATE TABLE Trips (
    trip_id         SERIAL PRIMARY KEY,
    user_id         INT NOT NULL,
    start_time      TIMESTAMP NOT NULL,
    done            BOOLEAN NOT NULL,
    data            JSONB NOT NULL,
    distance        REAL NOT NULL, 

    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE ROLE dg_api WITH LOGIN PASSWORD 'secure';
GRANT CONNECT ON DATABASE dg_db TO dg_api;
GRANT USAGE ON SCHEMA public TO dg_api;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO dg_api;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dg_api;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT ON TABLES TO dg_api;
