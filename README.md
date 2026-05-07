We use [**Docker Compose**](https://docs.docker.com/compose/) for easy deployment

1. [Install Docker Compose](https://docs.docker.com/compose/install/)
2. Set up the env file (see `.env.example` for reference)
3. Run the application
```bash
docker buildx bake -f docker-bake.hcl -f .env  # this has to be done online!
docker compose up
```
