"""Transactional storage and authentication. All application logic is Jac."""
import sqlite3;
import json;
import os;
import secrets;
import hashlib;
import hmac;
import time;
import from pathlib { Path }

def connect() -> sqlite3.Connection {
    location = os.getenv("HEHA_DB", ".jac/data/heha.sqlite3");
    Path(location).parent.mkdir(parents=True, exist_ok=True);
    db = sqlite3.connect(location, timeout=15);
    db.row_factory = sqlite3.Row;
    db.execute("PRAGMA foreign_keys=ON");
    return db;
}

def uid() -> str { return secrets.token_hex(8); }

def password_hash(password: str, salt: str) -> str {
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 210000).hex();
}

def public_user(user: dict) -> dict {
    return {"id": user["id"], "name": user["name"], "email": user["email"], "role": user["role"]};
}

def rows(db: any, sql: str, params: tuple = ()) -> list[dict] {
    return [dict(row) for row in db.execute(sql, params).fetchall()];
}

def one(db: any, sql: str, params: tuple = ()) -> dict {
    found = rows(db, sql, params);
    if not found { raise ValueError("That record was not found."); }
    return found[0];
}

def current_user(db: any, token: str) -> dict {
    found = rows(db, "SELECT u.* FROM users u JOIN sessions s ON s.user_id=u.id WHERE s.token_hash=? AND s.expires>?", (hashlib.sha256(token.encode()).hexdigest(), time.time()));
    if not found { raise ValueError("Please sign in again to continue."); }
    return found[0];
}

def require_role(user: dict, role: str) {
    if user["role"] != role { raise ValueError("Your account cannot perform this action."); }
}

def event(db: any, booking_id: str, actor: str, message: str) {
    db.execute("INSERT INTO events VALUES(?,?,?,?,?)", (uid(), booking_id, actor, message, time.time()));
}

def initialize() {
    with connect() as db {
        db.executescript("""
        CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY,name TEXT NOT NULL,email TEXT UNIQUE NOT NULL,role TEXT NOT NULL,salt TEXT NOT NULL,password_hash TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS sessions(token_hash TEXT PRIMARY KEY,user_id TEXT REFERENCES users(id),expires REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS movers(id TEXT PRIMARY KEY,user_id TEXT UNIQUE REFERENCES users(id),name TEXT NOT NULL,area TEXT NOT NULL,bio TEXT NOT NULL,rate INTEGER NOT NULL,capacity INTEGER NOT NULL,verified INTEGER NOT NULL DEFAULT 0,rating REAL NOT NULL DEFAULT 0,jobs INTEGER NOT NULL DEFAULT 0,services TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS bookings(id TEXT PRIMARY KEY,customer_id TEXT REFERENCES users(id),pickup TEXT NOT NULL,destination TEXT NOT NULL,move_date TEXT NOT NULL,size INTEGER NOT NULL,packing INTEGER NOT NULL,budget INTEGER NOT NULL,notes TEXT NOT NULL,status TEXT NOT NULL,accepted_quote TEXT,created REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS quotes(id TEXT PRIMARY KEY,booking_id TEXT REFERENCES bookings(id),mover_id TEXT REFERENCES movers(id),amount INTEGER NOT NULL,message TEXT NOT NULL,status TEXT NOT NULL,created REAL NOT NULL,UNIQUE(booking_id,mover_id));
        CREATE TABLE IF NOT EXISTS events(id TEXT PRIMARY KEY,booking_id TEXT REFERENCES bookings(id),actor TEXT NOT NULL,message TEXT NOT NULL,created REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS payments(id TEXT PRIMARY KEY,booking_id TEXT UNIQUE REFERENCES bookings(id),amount INTEGER NOT NULL,reference TEXT NOT NULL,created REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS reviews(id TEXT PRIMARY KEY,booking_id TEXT UNIQUE REFERENCES bookings(id),mover_id TEXT REFERENCES movers(id),rating INTEGER NOT NULL,comment TEXT NOT NULL,created REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS messages(id TEXT PRIMARY KEY,booking_id TEXT REFERENCES bookings(id),author_id TEXT REFERENCES users(id),author_name TEXT NOT NULL,author_role TEXT NOT NULL,body TEXT NOT NULL,created REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS checklist(booking_id TEXT REFERENCES bookings(id),code TEXT NOT NULL,completed REAL NOT NULL,PRIMARY KEY(booking_id,code));
        """);
        if os.getenv("HEHA_DEMO", "1") == "1" and not rows(db, "SELECT id FROM users LIMIT 1") {
            seed_demo(db);
        }
    }
}

def add_user(db: any, name: str, email: str, password: str, role: str) -> str {
    ident = uid(); salt = secrets.token_hex(16);
    db.execute("INSERT INTO users VALUES(?,?,?,?,?,?)", (ident, name, email, role, salt, password_hash(password, salt)));
    return ident;
}

def seed_demo(db: any) {
    add_user(db, "Alex Kamau", "customer@heha.demo", "HehaDemo2026!", "customer");
    add_user(db, "Heha Operations", "admin@heha.demo", "HehaDemo2026!", "admin");
    companies = [
        ("Nairobi Swift Movers", "mover@heha.demo", "Nairobi", 6500, 4, 4.9, 128, "packing,assembly,fragile", "Careful crews. Clear prices. A fresh start, without the stress."),
        ("Green Route Relocations", "green@heha.demo", "Nairobi", 4800, 3, 4.7, 86, "packing,eco", "Reusable crates and efficient routes for a lighter move."),
        ("Rift Valley Movers", "rift@heha.demo", "Nakuru", 5500, 5, 4.8, 94, "packing,assembly,long-distance", "From the city to the Rift: dependable moves across Kenya."),
        ("Coast Care Logistics", "coast@heha.demo", "Mombasa", 7200, 5, 4.8, 73, "packing,fragile,long-distance", "Coast-to-city relocation with a personal touch."),
        ("Urban Carry", "urban@heha.demo", "Nairobi", 3200, 2, 4.6, 52, "assembly,small-moves", "Smart, affordable moves for studios and first homes."),
        ("Lakeview Moving Co.", "lake@heha.demo", "Kisumu", 5000, 4, 4.7, 61, "packing,long-distance", "Local knowledge, nationwide reach. Your belongings in safe hands.")
    ];
    for c in companies {
        owner = add_user(db, c[0], c[1], "HehaDemo2026!", "mover");
        db.execute("INSERT INTO movers VALUES(?,?,?,?,?,?,?,?,?,?,?)", (uid(), owner, c[0], c[2], c[8], c[3], c[4], 1, c[5], c[6], c[7]));
    }
}
