# Allow the container's matching user ID to access your display.
xhost +SI:localuser:"$(id -un)"

docker compose up -d

docker compose exec frasky_test bash