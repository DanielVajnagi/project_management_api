Below is an example README file that documents all of the features of your application:

---

# Project Manager API

This Rails API application allows authenticated users to manage their projects and tasks. Projects are owned by users, and each project can have multiple tasks. Tasks support filtering by status.

## Features

### Authentication

- **User Authentication:**
  Uses [Devise](https://github.com/heartcombo/devise) for user authentication.
- **JWT Authorization:**
  Authenticates API requests using JSON Web Tokens (JWT) via [devise-jwt](https://github.com/waiting-for-dev/devise-jwt).
  All API endpoints require a valid JWT in the `Authorization` header (formatted as `Bearer <token>`).

### Projects API

- **List Projects:**
  `GET /api/projects`
  Returns a list of projects that belong to the authenticated user. Each project includes its associated tasks.

- **View a Project:**
  `GET /api/projects/:id`
  Retrieves details of a single project.
  - Returns **404 Not Found** if the project doesn’t exist or is not owned by the user.

- **Create a Project:**
  `POST /api/projects`
  Creates a new project for the authenticated user.
  - Requires valid parameters (e.g., `title` and `description`).
  - Returns **422 Unprocessable Entity** with errors if validations fail.

- **Update a Project:**
  `PATCH/PUT /api/projects/:id`
  Updates an existing project.
  - Only the project owner is authorized to update it; attempts by other users will return **403 Forbidden**.
  - If the project is not found, returns **404 Not Found**.

- **Delete a Project:**
  `DELETE /api/projects/:id`
  Deletes a project.
  - Only the project owner can delete it; otherwise, returns **403 Forbidden**.
  - Returns **404 Not Found** if the project doesn’t exist.

### Tasks API

Tasks are nested under projects.

- **List Tasks:**
  `GET /api/projects/:project_id/tasks`
  Retrieves a list of tasks for a specific project.
  - **Filtering:**
    Use the optional query parameter `status` to filter tasks by status. For example:
    `GET /api/projects/1/tasks?status=done` returns only tasks with a status of `done`.

- **View a Task:**
  `GET /api/projects/:project_id/tasks/:id`
  Retrieves details of a single task.
  - Returns **404 Not Found** if the task is not found.

- **Create a Task:**
  `POST /api/projects/:project_id/tasks`
  Creates a new task within a project.
  - **Valid Attributes:**
    - `title` (required)
    - `description` (optional)
    - `status` (enum: `not_started`, `in_progress`, `done`; default is `not_started`)
  - Returns **422 Unprocessable Entity** if validations fail.

- **Update a Task:**
  `PATCH/PUT /api/projects/:project_id/tasks/:id`
  Updates an existing task.
  - Only the owner of the project can update its tasks.
  - Unauthorized attempts return **403 Forbidden**.

- **Delete a Task:**
  `DELETE /api/projects/:project_id/tasks/:id`
  Deletes a task from the project.
  - Only the project owner can delete tasks; unauthorized requests return **403 Forbidden**.

### Data Models

#### Project
- **Attributes:**
  - `title`: string, required
  - `description`: text
- **Associations:**
  - Belongs to a user
  - Has many tasks

#### Task
- **Attributes:**
  - `title`: string, required
  - `description`: text
  - `status`: enum with values:
    - `not_started` (default)
    - `in_progress`
    - `done`
- **Associations:**
  - Belongs to a project

### Error Handling

- **401 Unauthorized:**
  Returned when a request is made without a valid JWT token.
- **403 Forbidden:**
  Returned when an authenticated user attempts to modify a resource they do not own.
- **404 Not Found:**
  Returned when the requested resource (project or task) does not exist.
- **422 Unprocessable Entity:**
  Returned when data validations fail during creation or update.

## Installation and Setup

### Prerequisites

- Ruby 3.3.7
- Rails 7.2
- PostgreSQL

### Setup Steps

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   ```

2. **Install Dependencies:**

   ```bash
   bundle install
   ```

3. **Setup the Database:**

   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Set Up Credentials:**
   Ensure your Rails credentials include the `secret_key_base` needed for JWT token encoding. You can edit credentials by running:

   ```bash
   EDITOR="nano" rails credentials:edit
   ```

5. **Verify Database Setup:**
  Check your config/database.yml to ensure that the database configuration is correct for your environment (development, test, and production).

6. **Run the Server:**

   ```bash
   rails server
   ```

## Testing

- The application includes RSpec request specs for the Projects and Tasks APIs.
- To run the tests:

  ```bash
  bundle exec rspec
  ```

## Example Usage

### Authenticate

Obtain a JWT token by authenticating the user (typically via your login endpoint). Then use the token in your request headers:

```
Authorization: Bearer <your_jwt_token>
```

### Example: List Projects

```bash
GET /api/projects
```

### Example: Filter Tasks by Status

```bash
GET /api/projects/1/tasks?status=done
```

This returns only tasks within project 1 that have a status of `done`.
