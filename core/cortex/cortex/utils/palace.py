import sqlite3

DB = "/data/data/com.termux/files/home/Z-GENESIS-PALACE/DSN-PALACE.db"

def palace_query(text):
    conn = sqlite3.connect(DB)
    cur = conn.cursor()
    cur.execute(
        "SELECT id, room_id, content, timestamp FROM drawers WHERE content LIKE ?",
        (f"%{text}%",)
    )
    rows = cur.fetchall()
    conn.close()
    return rows

def palace_add(room_id, content):
    conn = sqlite3.connect(DB)
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO drawers(room_id, content, timestamp) VALUES (?, ?, datetime('now'))",
        (room_id, content)
    )
    conn.commit()
    conn.close()
