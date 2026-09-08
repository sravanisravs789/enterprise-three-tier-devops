CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO tasks (title)
VALUES
    ('Configure AWS infrastructure'),
    ('Build CI/CD pipeline'),
    ('Deploy application to EKS');
