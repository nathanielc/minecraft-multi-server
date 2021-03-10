#!/bin/bash

# Launch Minecraft docker container

set -e

# Default listen port
# This is the published host port,
# internally the container always listens on 25565
PORT=${PORT-25565}

# Default listen port for rcon
# This is the published host port,
# internally the container always listens on 25575
RCON_PORT=${RCON_PORT-25575}
RCON_CMD="mcrcon -P ${RCON_PORT}"
if [ -n "$RCON_PASSWORD" ]
then
    RCON_CMD="${RCON_CMD} -p ${RCON_PASSWORD}"
else
    RCON_CMD="${RCON_CMD} -p minecraft"
fi

# Default max java heap size in MB
MAXHEAP=${MAXHEAP-2048}

# Default min java heap size in MB
MINHEAP=${MINHEAP-512}

# Path to docker executable
DOCKER=${DOCKER-$(which docker)}

# Wether to mount a persistent volume for the server
# If true a volume will not be mounted and a restart will lose all world data
EPHEMERAL=${EPHEMERAL-false}

# Directory for persisting minecraft data
DATA_DIR=${DATA_DIR-/srv/minecraft}
# Relative directory to $DATA_DIR for saving minecraft backups
BACKUP_DIR=${BACKUP_DIR-"./backups"}

# IDs of minecraft user and group
MINECRAFT_UID=${MINECRAFT_UID-$(id -u minecraft)}
MINECRAFT_GID=${MINECRAFT_GID-$(id -g minecraft)}

# Name of world dir
LEVEL=${LEVEL-world}

# Game command timeout
TIMEOUT=${TIMEOUT-0}

usage() {
    echo "Usage: $0 [start|stop|restart|status|save|backup] <name>"
    echo ""
    echo "Name is a name for the container and the data dir"
    exit 1
}

# Check if container is running
running() {
    status="$($DOCKER inspect -f '{{.State.Status}}' "$name" 2>/dev/null)"
    test running = "$status"
    return $?
}

# Start the minecraft docker container
start() {
    if running
    then
        echo "Server already running..."
        exit 0
    fi
    stop_container

    vol_mount="--volume=$DATA_DIR/$name:/data"
    if $EPHEMERAL
    then
        vol_mount=""
        echo "Ephemeral server, a restart will lose all world data"
    fi

    $DOCKER run -d -i \
        --name "$name" \
        $vol_mount \
        -p $PORT:25565 \
        -p $RCON_PORT:25575 \
        -e "RCON_PASSWORD=${RCON_PASSWORD}" \
        -e "JVM_OPTS=-D${name}" \
        -e "INIT_MEMORY=${MINHEAP}M" \
        -e "MAX_MEMORY=${MAXHEAP}M" \
        -e "JVM_XX_OPTS=${EXTRA_JVM_OPTS}" \
        -e "EULA=$EULA" \
        -e "VERSION=$VERSION" \
        -e "DIFFICULTY=$DIFFICULTY" \
        -e "WHITELIST=$WHITELIST" \
        -e "OPS=$OPS" \
        -e "ICON=$ICON" \
        -e "MAX_PLAYERS=$MAX_PLAYERS" \
        -e "MAX_WORLD_SIZE=$MAX_WORLD_SIZE" \
        -e "ALLOW_NETHER=$ALLOW_NETHER" \
        -e "ANNOUNCE_PLAYER_ACHIEVEMENTS=$ANNOUNCE_PLAYER_ACHIEVEMENTS" \
        -e "ENABLE_COMMAND_BLOCK=$ENABLE_COMMAND_BLOCK" \
        -e "FORCE_GAMEMODE=$FORCE_GAMEMODE" \
        -e "GENERATE_STRUCTURES=$GENERATE_STRUCTURES" \
        -e "HARDCORE=$HARDCORE" \
        -e "MAX_BUILD_HEIGHT=$MAX_BUILD_HEIGHT" \
        -e "MAX_TICK_TIME=$MAX_TICK_TIME" \
        -e "SPAWN_MONSTERS=$SPAWN_MONSTERS" \
        -e "SPAWN_NPCS=$SPAWN_NPCS" \
        -e "VIEW_DISTANCE=$VIEW_DISTANCE" \
        -e "SEED=$SEED" \
        -e "MODE=$MODE" \
        -e "MOTD=$MOTD" \
        -e "PVP=$PVP" \
        -e "LEVEL_TYPE=$LEVEL_TYPE" \
        -e "GENERATOR_SETTINGS=$GENERATOR_SETTINGS" \
        -e "LEVEL=$LEVEL" \
        -e "WORLD=$WORLD" \
        -e "UID=$MINECRAFT_UID" \
        -e "GID=$MINECRAFT_GID" \
        itzg/minecraft-server

    echo "Started minecraft container $name"

}

# Send a command to the game server
game_command() {
    # Issue command
    $RCON_CMD "$1"
}

# Do a world save
save() {
    game_command "save-all flush"
    game_command "say Saved the world"
}


# Do a world backup
backup() {
    filename="$name-$(date +%Y_%m_%d_%H.%M.%S).tar.gz"

    game_command "say Starting backup..."
    # Make sure we always turn saves back on
    set +e
    ret=0
    game_command "save-off"
    ret=$(($ret + $?))
    game_command "save-all flush"
    ret=$(($ret + $?))
    sync
    ret=$(($ret + $?))
    $DOCKER exec -u minecraft "$name" mkdir -p "/data/$BACKUP_DIR"
    ret=$(($ret + $?))
    $DOCKER exec -u minecraft "$name" tar -C /data -czf "$BACKUP_DIR/$filename" "$LEVEL" server.properties
    ret=$(($ret + $?))
    game_command "save-on"
    ret=$(($ret + $?))

    game_command "say Backup finished"
    exit $ret
}

# Stop the server
stop() {
    if running
    then
        game_command "save-all"
        for i in {3..1}
        do
            game_command "say Server shutting down in ${i}s..."
            sleep 1
        done
        game_command "say Shutting down..."
        game_command "stop"
        # Wait for container to stop on its own now
        $DOCKER wait "$name"
    fi

    stop_container
}

# Stop the container
stop_container() {
    $DOCKER stop "$name" > /dev/null 2>&1 || true
    $DOCKER rm "$name" > /dev/null 2>&1 || true
}


name=$2
if [ -z "$name" ]
then
    usage
fi

if [ -n "$DEBUG" ]
then
    set -x
fi

case "$1" in
status)
    if running
    then
        echo "Minecraft server $name is running"
        exit 0
    else
        echo "Minecraft server $name is stopped"
        exit 2
    fi
    ;;
start)
    start
    ;;
stop)
    stop
    ;;
restart)
    stop
    start
    ;;
backup)
    backup
    ;;
save)
    save
    ;;
*)
    usage
    ;;
esac

