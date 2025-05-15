
CREATE TYPE userclass AS ENUM ('user', 'admin', 'insurance');

DROP TABLE IF EXISTS Users CASCADE;
CREATE TABLE IF NOT EXISTS Users (
    user_id         SERIAL PRIMARY KEY,        
    first_name      VARCHAR(100) NOT NULL, 
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    class           userclass NOT NULL, 
    password_hash   BYTEA NOT NULL, 
    salt            BYTEA NOT NULL,
    brake_score     REAL NOT NULL,  
    accel_score     REAL NOT NULL, 
    score           REAL NOT NULL 
);

DROP TABLE IF EXISTS Trips CASCADE;
CREATE TABLE IF NOT EXISTS Trips (
    trip_id         SERIAL PRIMARY KEY,
    user_id         INT NOT NULL,
    start_time      TIMESTAMP NOT NULL,
    data            JSONB NOT NULL,
    
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS TripMetrics CASCADE;
CREATE TABLE IF NOT EXISTS TripsMetrics (
    trip_id     INT NOT NULL,    
    distance    REAL NOT NULL, 
    avg_velo    REAL NOT NULL, 
    max_velo    REAL NOT NULL, 
    brake_score   REAL NOT NULL,
    accel_score   REAL NOT NULL,
    trip_score  REAL NOT NULL,

    FOREIGN KEY (trip_id) REFERENCES Trips(trip_id) ON DELETE CASCADE
);

CREATE TABLE insurance (
    id SERIAL PRIMARY KEY,          -- Auto-incrementing unique ID
    policy_name VARCHAR(255) NOT NULL, -- Name of the insurance policy
    description TEXT NOT NULL,      -- Description of the policy
    premium VARCHAR(50) NOT NULL    -- Premium amount (e.g., "$500")
);



CREATE TABLE server_information (
    id SERIAL PRIMARY KEY,          -- Auto-incrementing unique ID
    base_url VARCHAR(255) NOT NULL, -- Base URL of the server
    port VARCHAR(10) NOT NULL,      -- Port number as a string
    api_key VARCHAR(255) NOT NULL   -- API key for the server
);
