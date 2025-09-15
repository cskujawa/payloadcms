#!/bin/sh
set -e

echo "🚀 PayloadCMS Docker Entrypoint"

# If package.json doesn't exist, initialize PayloadCMS project
if [ ! -f "package.json" ]; then
    echo "📦 No package.json found - initializing PayloadCMS project..."

    # Check if running as root, if so setup corepack then switch to node user
    if [ "$(id -u)" = "0" ]; then
        echo "🔧 Setting up corepack as root..."
        corepack enable
        corepack prepare pnpm@latest --activate

        echo "👤 Switching to node user for project initialization..."
        # Change ownership of working directory to node user
        chown -R node:node /app

        # Execute rest of script as node user
        exec su-exec node "$0" "$@"
    fi

    # Now running as node user - corepack should already be set up

    # Use create-payload-app to initialize in a temporary directory
    echo "🏗️  Creating PayloadCMS project..."
    npx create-payload-app@latest payloadcms-temp \
        --name=payloadcms-docker \
        --template=blank \
        --db=mongodb \
        --db-connection-string="${DATABASE_URI}" \
        --no-deps \
        --yes

    # Move files from subdirectory to current directory
    echo "📂 Moving project files to working directory..."

    # The tool creates a directory with the --name value, so look for that
    if [ -d "payloadcms-docker" ]; then
        echo "✅ Found payloadcms-docker directory"
        # Move all files including hidden ones
        find payloadcms-docker -mindepth 1 -maxdepth 1 -exec mv {} . \; 2>/dev/null || true
        rmdir payloadcms-docker 2>/dev/null || true
        echo "📂 Files moved successfully"
    else
        echo "❌ PayloadCMS directory not found! Available directories:"
        ls -la
    fi

    # Ensure Next.js config has standalone output for Docker
    if [ -f "next.config.mjs" ]; then
        echo "⚙️  Configuring Next.js for Docker standalone output..."
        if ! grep -q "output.*standalone" next.config.mjs; then
            # Add standalone output if not present
            sed -i "s/const nextConfig = {/const nextConfig = {\n  output: 'standalone',/" next.config.mjs
        fi
    fi

    # Set proper ownership (if running as root, change to node user)
    if [ "$(id -u)" = "0" ]; then
        chown -R node:node . 2>/dev/null || true
    fi

    echo "✅ PayloadCMS project initialized successfully"
else
    echo "✅ Existing PayloadCMS project found"

    # If running as root but project exists, switch to node user
    if [ "$(id -u)" = "0" ]; then
        echo "👤 Switching to node user..."
        chown -R node:node /app
        exec su-exec node "$0" "$@"
    fi
fi

# Now running as node user - ensure pnpm is available
if ! command -v pnpm >/dev/null 2>&1; then
    echo "📦 Setting up pnpm for node user..."
    corepack enable
    corepack prepare pnpm@latest --activate
fi

# Install dependencies
echo "📦 Installing dependencies..."
pnpm install

# Start development server
echo "🚀 Starting PayloadCMS development server..."
exec pnpm dev