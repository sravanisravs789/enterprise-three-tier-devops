const API_URL = "/api";

const taskForm = document.getElementById("taskForm");
const taskInput = document.getElementById("taskInput");
const taskList = document.getElementById("taskList");

async function loadTasks() {
    try {
        const response = await fetch(`${API_URL}/tasks`);

        if (!response.ok) {
            throw new Error("Failed to fetch tasks");
        }

        const tasks = await response.json();

        taskList.innerHTML = "";

        tasks.forEach(task => {
            const li = document.createElement("li");
            li.textContent = task.title;
            taskList.appendChild(li);
        });

    } catch (error) {
        console.error(error);
    }
}

taskForm.addEventListener("submit", async (event) => {

    event.preventDefault();

    const title = taskInput.value.trim();

    if (!title) {
        return;
    }

    try {

        const response = await fetch(`${API_URL}/tasks`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ title })
        });

        if (!response.ok) {
            throw new Error("Failed to create task");
        }

        taskInput.value = "";

        await loadTasks();

    } catch (error) {
        console.error(error);
    }
});

loadTasks();
