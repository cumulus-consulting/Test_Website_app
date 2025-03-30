document.addEventListener("DOMContentLoaded", () => {
  const todoForm = document.getElementById("todo-form");
  const todoInput = document.getElementById("todo-input");
  const todoList = document.getElementById("todo-list");
  const loadingSpinner = document.getElementById("loading-spinner");
  const errorMessage = document.getElementById("error-message");


  const API_URL = "/api/todos";

  let todos = [];

  function showSpinner() {
    loadingSpinner.style.display = "inline-block";
  }
  function hideSpinner() {
    loadingSpinner.style.display = "none";
  }

  function showError(msg) {
    errorMessage.textContent = msg;
    errorMessage.style.display = "block";
  }
  function hideError() {
    errorMessage.textContent = "";
    errorMessage.style.display = "none";
  }

  async function loadTodos() {
    showSpinner();
    hideError();

    try {
      const res = await fetch(API_URL);
      if (!res.ok) {
        throw new Error(`Server returned ${res.status}`);
      }
      todos = await res.json(); 
      renderTodos();
    } catch (error) {
      console.error("Error loading todos:", error);
      showError("Unable to load your to-dos. Please try again later.");
      todos = []; 
    } finally {
      hideSpinner();
    }
  }

  async function addTodo(text) {
    showSpinner();
    hideError();

    try {
      const res = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text }),
      });

      if (!res.ok) {
        throw new Error(`Server returned ${res.status}`);
      }
      const newTodo = await res.json();
      todos.push(newTodo);
      renderTodos();
    } catch (error) {
      console.error("Error adding todo:", error);
      showError("Unable to add a new to-do. Please try again.");
    } finally {
      hideSpinner();
    }
  }


  async function deleteTodo(id) {
    showSpinner();
    hideError();

    try {
      const res = await fetch(`${API_URL}/${id}`, { method: "DELETE" });
      if (!res.ok) {
        throw new Error(`Server returned ${res.status}`);
      }

      // Filter out the deleted item from local list
      todos = todos.filter((todo) => todo._id !== id);
      renderTodos();
    } catch (error) {
      console.error("Error deleting todo:", error);
      showError("Unable to delete this to-do. Please try again.");
    } finally {
      hideSpinner();
    }
  }


  function renderTodos() {
    todoList.innerHTML = ""; 
    todos.forEach((todo) => {
      const li = document.createElement("li");
      li.classList.add(
        "list-group-item",
        "d-flex",
        "justify-content-between",
        "align-items-center"
      );
      li.textContent = todo.text;

      const deleteBtn = document.createElement("button");
      deleteBtn.textContent = "Delete";
      deleteBtn.classList.add("btn", "btn-danger", "btn-sm");
      deleteBtn.addEventListener("click", () => {
        deleteTodo(todo._id);
      });

      li.appendChild(deleteBtn);
      todoList.appendChild(li);
    });
  }


  todoForm.addEventListener("submit", (e) => {
    e.preventDefault();
    const text = todoInput.value.trim();
    if (text !== "") {
      addTodo(text);
      todoInput.value = "";
    }
  });

  loadTodos();
});
