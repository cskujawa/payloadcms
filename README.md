# PayloadCMS Docker Setup

A complete Docker Compose setup for [PayloadCMS](https://github.com/payloadcms/payload) with MongoDB database, featuring automatic project initialization and development workflow.

##  Quick Start

```bash
git clone https://github.com/cskujawa/payloadcms.git
cd payloadcms
cp .env.example .env
# Edit .env file and change PAYLOAD_SECRET to a secure random string
./scripts/setup.sh
```

Access your PayloadCMS admin at: **http://localhost:3000/admin**

##  Features

- **Automatic Initialization**: PayloadCMS project created automatically on first run
- **Zero Host Dependencies**: Everything runs in Docker containers
- **Development Ready**: Live reloading with volume mounts
- **Protected Configuration**: Custom Docker files won't be overwritten
- **Easy Management**: Setup and cleanup scripts included
- **MongoDB Integration**: Internal Docker networking for database

##  Project Structure

```
payloadcms/
├── docker-compose.yaml           # Main orchestration
├── .env.example                 # Environment template
├── scripts/                     # Management scripts
│   ├── setup.sh                # Full setup and port checking
│   └── manage.sh               # Cleanup and management
└── data/
    └── payloadcms/
        ├── Dockerfile.dev              # Custom development Dockerfile
        └── docker-entrypoint.dev.sh   # Initialization script
```

##  Management Commands

```bash
# Full setup (recommended)
./scripts/setup.sh

# Complete cleanup
./scripts/manage.sh cleanup

# Manual Docker commands
docker compose up -d          # Start services
docker compose down           # Stop services
docker compose logs -f        # View logs
```

##  Configuration

The setup uses these key environment variables:

- `PAYLOAD_SECRET`: Secure random string for PayloadCMS
- `DATABASE_URI`: MongoDB connection (internal Docker network)
- `PAYLOADCMS_HOST_PORT`: External port for web access (default: 3000)

##  Technical Details

- **PayloadCMS v3**: Latest version with Next.js integration
- **MongoDB**: Latest version with WiredTiger storage
- **Node.js 18**: Alpine Linux containers for efficiency
- **Automatic Project Creation**: Uses `create-payload-app` on first run
- **Development Optimized**: Volume mounts for live development

##  License

MIT License - feel free to use and modify as needed.
