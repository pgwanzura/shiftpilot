#!/bin/bash
# setup.sh

echo "🚀 Setting up ShiftPilot Development Environment..."

# Check hosts file entries
echo "🌐 Checking hosts file entries..."
if ! grep -q "traefik.localhost" /etc/hosts; then
    echo "❌ Please add '127.0.0.1 traefik.localhost' to your /etc/hosts file"
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose down

# Build and start services
echo "🐳 Building Docker images..."
docker-compose build

echo "🚀 Starting database services first..."
docker-compose up -d backend-database backend-redis

# Wait for MySQL to be ready with better checking
echo "⏳ Waiting for MySQL to be ready..."
for i in {1..60}; do
    if docker-compose exec -T backend-database mysql -ushiftpilot -ppassword -e "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ MySQL is ready and accepting connections!"
        break
    fi
    echo "Waiting for MySQL... ($i/60)"
    sleep 3
done

# Start the rest of the services
echo "🚀 Starting application services..."
docker-compose up -d backend-app frontend-app traefik

# Wait for backend to be ready
echo "⏳ Waiting for backend to be ready..."
for i in {1..30}; do
    if curl -f http://backend.localhost/api/health > /dev/null 2>&1; then
        echo "✅ Backend is ready!"
        break
    fi
    echo "Waiting for backend... ($i/30)"
    sleep 3
done

# Run backend setup
echo "🔧 Setting up backend..."
docker-compose exec backend-app composer install
docker-compose exec backend-app php artisan key:generate

# Run migrations with retry logic
echo "🗃️ Running database migrations..."
for i in {1..5}; do
    if docker-compose exec backend-app php artisan migrate; then
        echo "✅ Migrations completed successfully!"
        break
    else
        echo "❌ Migration attempt $i failed, retrying in 5 seconds..."
        sleep 5
    fi
done

echo "✅ Setup complete!"
echo ""
echo "🎉 Your ShiftPilot environment is ready!"
echo "   Frontend: http://frontend.localhost"
echo "   Backend API: http://backend.localhost"
echo "   Traefik Dashboard: http://traefik.localhost"
echo "   MySQL (from host): localhost:3307"
echo "   Redis (from host): localhost:6380"