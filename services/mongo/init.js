// Database name from MONGO_INITDB_DATABASE
const dbName = "raw_db";

db = db.getSiblingDB(dbName);

db.createUser({
    user: "appuser",
    pwd: "apppassword",
    roles: [
        { role: "readWrite", db: dbName }
    ]
});

print("Created user 'appuser' for database: " + dbName);
