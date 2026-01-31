#!/usr/bin/env bash
# Examples for running the container
# Build the image
#   docker build -t wp-demo .
# Run with seeding (expects env.yaml mounted)
#   docker run -d --name wp-demo \
#     -p 8080:80 -p 8081:8081 \
#     -v $(pwd)/env.yaml:/config/env.yaml:ro \
#     -v $(pwd):/workspace \
#     wp-demo
# Restore from backup
#   docker run --rm \
#     -v $(pwd)/env.yaml:/config/env.yaml:ro \
#     -v $(pwd):/workspace \
#     wp-demo --restore /workspace/db_backup.tgz
# Skip DB actions and just start services
#   docker run -d --name wp-demo-skip \
#     -p 8080:80 -p 8081:8081 \
#     -v $(pwd)/env.yaml:/config/env.yaml:ro \
#     -v $(pwd):/workspace \
#     wp-demo --skip-db
