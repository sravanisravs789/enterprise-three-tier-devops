const express = require("express");
const pool = require("./db");

const app = express();

const PORT = process.env.PORT || 4000;

app.use(express.json());

app.get("/health", async (req, res) => {

    try {

        await pool.query("SELECT 1");

        res.status(200).json({
            status: "healthy",
            database: "connected"
        });

    } catch (error) {

        res.status(503).json({
            status: "unhealthy",
            database: "disconnected"
        });

    }
});

app.get("/tasks", async (req, res) => {

    try {

        const result = await pool.query(
            "SELECT id, title, created_at FROM tasks ORDER BY id DESC"
        );

        res.json(result.rows);

    } catch (error) {

        console.error(error);

        res.status(500).json({
            error: "Unable to retrieve tasks"
        });
    }
});

app.post("/tasks", async (req, res) => {

    const { title } = req.body;

    if (!title || !title.trim()) {

        return res.status(400).json({
            error: "Task title is required"
        });
    }

    try {

        const result = await pool.query(
            "INSERT INTO tasks (title) VALUES ($1) RETURNING *",
            [title.trim()]
        );

        res.status(201).json(result.rows[0]);

    } catch (error) {

        console.error(error);

        res.status(500).json({
            error: "Unable to create task"
        });
    }
});

app.listen(PORT, "0.0.0.0", () => {

    console.log(`Backend API running on port ${PORT}`);

});
