# Self-Hosting Stemplin with Docker Compose

This guide provides step-by-step instructions for self-hosting Stemplin using Docker Compose.

## Prerequisites

A linux server setup with:

- [Docker](https://docs.docker.com/get-docker/) (version 20.10 or higher)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0 or higher)
- [Nginx](https://nginx.org/) - For reverse proxy and SSL termination in production

## Starting the Application

### 1. Clone the Repository

```bash
git clone https://github.com/rubynor/stemplin.git
cd stemplin
```

### 2. Configure Environment

Copy the sample environment file:

```bash
cp .env.sample .env
```

**Environment configuration:**
- `SECRET_KEY_BASE` - Generate a secure secret key:
  ```bash
  docker run --rm kaosper/stemplin:latest bundle exec rails secret
  ```
  Add the generated key to your `.env` file:
  ```
  SECRET_KEY_BASE=your_generated_key_here
  ```

- `SENTRY_KEY` - For error tracking (optional)
- `HTTP_HOST` - Your domain
- `RAILS_LOG_LEVEL` - Options: debug info warn error fatal unknown (default: info)
- `SENDGRID_API_KEY` - For email delivery. Sendgrid is currently required for the app to work properly.

At this point you have to create your own dynamic email templates in Sendgrid for the mailer to work :(
These are the required parameters for each email template:

- `WELCOME_EN_TEMPLATE_ID`: `organization_name`, `user_name`, `url`
- `WELCOME_NB_TEMPLATE_ID`: `organization_name`, `user_name`, `url`
- `PASSWORD_RESET_EN_TEMPLATE_ID`: `user_name`, `user_email`, `url`
- `PASSWORD_RESET_NB_TEMPLATE_ID`: `user_name`, `user_email`, `url`
- `PROJECT_INVITATION_EN_TEMPLATE_ID`: `organization_name`, `user_name`, `url`
- `PROJECT_INVITATION_NB_TEMPLATE_ID`: `organization_name`, `user_name`, `url`

### 3. Start the Services

```bash
docker-compose up -d
```

This starts PostgreSQL, Redis, the web server, and Sidekiq.

## Stopping the Application

Stop all services:
```bash
docker-compose down
```

Stop and remove all data (database and Redis):
```bash
docker-compose down -v
```

## Troubleshooting

### View Logs

View logs from all services:
```bash
docker-compose logs -f
```

View logs from a specific service:
```bash
docker-compose logs -f web
docker-compose logs -f sidekiq
docker-compose logs -f db
```

All services should show "Up" status.

### Access Rails Console

For debugging:
```bash
docker-compose exec web rails console
```
