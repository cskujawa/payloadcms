#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}PayloadCMS Management Tool${NC}"
    echo "Essential management commands for PayloadCMS"
    echo ""
    echo -e "${CYAN}Usage:${NC} $0 [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  ${GREEN}cleanup${NC}              Clean up containers and volumes"
    echo ""
    echo -e "${CYAN}Options:${NC}"
    echo "  --help, -h           Show this help"
    echo "  --yes, -y            Skip confirmation prompts"
    echo ""
}

# Confirmation function
confirm_action() {
    local message="$1"
    if [ "$SKIP_CONFIRM" != "true" ]; then
        echo -e "${RED}⚠️  $message${NC}"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi
}

# Cleanup functionality
cleanup_system() {
    echo -e "${BLUE}🧹 PayloadCMS Complete Cleanup${NC}"

    confirm_action "This will remove all PayloadCMS containers, volumes, and data!"

    echo "🛑 Stopping services..."
    docker compose down --remove-orphans 2>/dev/null || true

    echo "🗑️  Removing containers..."
    PAYLOADCMS_CONTAINERS=$(docker ps -aq --filter "name=payloadcms" 2>/dev/null || true)
    if [ ! -z "$PAYLOADCMS_CONTAINERS" ]; then
        docker rm -f $PAYLOADCMS_CONTAINERS 2>/dev/null || true
    fi

    echo "💾 Removing volumes..."
    COMPOSE_VOLUMES="payloadcms_db_data payloadcms_node_modules"
    for volume in $COMPOSE_VOLUMES; do
        if docker volume ls -q | grep -q "^${volume}$"; then
            docker volume rm "$volume" 2>/dev/null || true
        fi
    done

    # Also remove any other payloadcms volumes
    PAYLOADCMS_VOLUMES=$(docker volume ls -q --filter "name=payloadcms" 2>/dev/null || true)
    if [ ! -z "$PAYLOADCMS_VOLUMES" ]; then
        echo "$PAYLOADCMS_VOLUMES" | while read -r volume; do
            docker volume rm "$volume" 2>/dev/null || true
        done
    fi

    echo "🌐 Removing networks..."
    PAYLOADCMS_NETWORKS=$(docker network ls -q --filter "name=smart-tilde" 2>/dev/null || true)
    if [ ! -z "$PAYLOADCMS_NETWORKS" ]; then
        echo "$PAYLOADCMS_NETWORKS" | while read -r network; do
            docker network rm "$network" 2>/dev/null || true
        done
    fi

    echo "🖼️  Removing images..."
    PAYLOADCMS_IMAGES=$(docker images -q --filter "reference=*payloadcms*" 2>/dev/null || true)
    if [ ! -z "$PAYLOADCMS_IMAGES" ]; then
        docker rmi -f $PAYLOADCMS_IMAGES 2>/dev/null || true
    fi

    echo "📁 Cleaning local files..."
    # Clean PayloadCMS generated files but keep our custom Docker files
    find ./data/payloadcms -mindepth 1 -not -name "Dockerfile.dev" -not -name "docker-entrypoint.dev.sh" -exec rm -rf {} + 2>/dev/null || true

    echo -e "${GREEN}✅ Cleanup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./scripts/setup.sh"
}



# Parse arguments
SKIP_CONFIRM="false"
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --yes|-y)
            SKIP_CONFIRM="true"
            shift
            ;;
        cleanup)
            if [ ! -z "$COMMAND" ]; then
                echo -e "${RED}❌ Only one command allowed${NC}"
                exit 1
            fi
            COMMAND="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute command
case $COMMAND in
    cleanup)
        cleanup_system
        ;;
    *)
        show_help
        exit 0
        ;;
esac