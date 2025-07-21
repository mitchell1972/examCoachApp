#!/bin/bash

# Exam Coach App Deployment Script
# This script helps you deploy the Flutter app to various platforms

set -e

echo "🎓 Exam Coach App Deployment Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed. Please install Flutter first:"
        echo "https://docs.flutter.dev/get-started/install"
        exit 1
    fi
    print_status "Flutter is installed"
}

# Enable web support
enable_web() {
    print_info "Enabling Flutter web support..."
    flutter config --enable-web
    print_status "Web support enabled"
}

# Install dependencies
install_deps() {
    print_info "Installing dependencies..."
    flutter pub get
    print_status "Dependencies installed"
}

# Build for web
build_web() {
    print_info "Building Flutter web app..."
    flutter build web --release --web-renderer canvaskit
    print_status "Web build completed"
}

# Serve locally
serve_local() {
    print_info "Starting local server..."
    cd build/web
    
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}🌐 App running at: http://localhost:8080${NC}"
        echo "Press Ctrl+C to stop"
        python3 -m http.server 8080
    elif command -v python &> /dev/null; then
        echo -e "${GREEN}🌐 App running at: http://localhost:8080${NC}"
        echo "Press Ctrl+C to stop"
        python -m http.server 8080
    else
        print_warning "Python not found. Please install Python to serve locally."
        print_info "Alternatively, use any web server to serve the 'build/web' directory"
    fi
}

# Initialize git repository
init_git() {
    if [ ! -d ".git" ]; then
        print_info "Initializing git repository..."
        git init
        git add .
        git commit -m "Initial commit: Secure Flutter Exam Coach App"
        print_status "Git repository initialized"
        print_info "Next steps:"
        echo "1. Create a repository on GitHub"
        echo "2. Run: git remote add origin https://github.com/YOUR_USERNAME/examCoachApp.git"
        echo "3. Run: git push -u origin main"
    else
        print_status "Git repository already exists"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "Choose deployment option:"
    echo "1) 🏠 Build and serve locally"
    echo "2) 📦 Build for production only"
    echo "3) 🔧 Setup for GitHub Pages"
    echo "4) 🌐 Setup for Netlify"
    echo "5) ⚡ Setup for Vercel"
    echo "6) 🔥 Setup for Firebase"
    echo "7) 🧪 Run tests"
    echo "8) 📋 Show deployment status"
    echo "0) Exit"
    echo ""
    read -p "Enter your choice (0-8): " choice
}

# Handle menu choices
handle_choice() {
    case $choice in
        1)
            check_flutter
            enable_web
            install_deps
            build_web
            serve_local
            ;;
        2)
            check_flutter
            enable_web
            install_deps
            build_web
            print_status "Production build completed in build/web/"
            ;;
        3)
            init_git
            print_info "GitHub Pages setup:"
            echo "1. Push your code to GitHub"
            echo "2. Go to Settings → Pages in your repository"
            echo "3. Select 'Deploy from a branch' and choose 'gh-pages'"
            echo "4. The GitHub Action will automatically deploy your app"
            ;;
        4)
            print_info "Netlify setup:"
            echo "1. Push your code to GitHub"
            echo "2. Go to netlify.com and connect your repository"
            echo "3. The netlify.toml file is already configured"
            echo "4. Your app will be deployed automatically"
            ;;
        5)
            print_info "Vercel setup:"
            echo "1. Push your code to GitHub"
            echo "2. Go to vercel.com and import your repository"
            echo "3. The vercel.json file is already configured"
            echo "4. Your app will be deployed automatically"
            ;;
        6)
            print_info "Firebase setup:"
            echo "1. Install Firebase CLI: npm install -g firebase-tools"
            echo "2. Run: firebase login"
            echo "3. Run: firebase init hosting"
            echo "4. Set public directory to: build/web"
            echo "5. Configure as single-page app: Yes"
            echo "6. Build the app and run: firebase deploy"
            ;;
        7)
            check_flutter
            print_info "Running Flutter tests..."
            flutter test
            print_info "Running Gherkin tests..."
            flutter drive --target=test_driver/app.dart &
            sleep 5
            flutter drive --target=test_driver/app_test.dart
            print_status "All tests completed"
            ;;
        8)
            echo ""
            echo "📊 Deployment Status:"
            echo "===================="
            
            if [ -d "build/web" ]; then
                print_status "Web build exists"
            else
                print_warning "No web build found. Run option 1 or 2 first."
            fi
            
            if [ -f ".github/workflows/deploy.yml" ]; then
                print_status "GitHub Actions configured"
            fi
            
            if [ -f "netlify.toml" ]; then
                print_status "Netlify configuration ready"
            fi
            
            if [ -f "vercel.json" ]; then
                print_status "Vercel configuration ready"
            fi
            
            if [ -d ".git" ]; then
                print_status "Git repository initialized"
            else
                print_warning "Git repository not initialized"
            fi
            ;;
        0)
            print_status "Goodbye! 👋"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            ;;
    esac
}

# Main execution
main() {
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "Please run this script from the Flutter project root directory"
        exit 1
    fi
    
    while true; do
        show_menu
        handle_choice
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run the script
main 