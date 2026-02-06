#!/bin/bash
# App Store Screenshot Capture Script for PWPro
# This script helps capture screenshots for App Store submission

# Configuration
APP_NAME="PWProApp"
SCREENSHOTS_DIR="$HOME/Desktop/PWPro_Screenshots"

# Create screenshots directory
mkdir -p "$SCREENSHOTS_DIR"
mkdir -p "$SCREENSHOTS_DIR/iPhone_6.7"
mkdir -p "$SCREENSHOTS_DIR/iPhone_6.5"
mkdir -p "$SCREENSHOTS_DIR/iPad_12.9"

echo "📱 PWPro App Store Screenshot Capture"
echo "======================================"
echo ""
echo "Screenshots will be saved to: $SCREENSHOTS_DIR"
echo ""

# List of simulators
echo "Available simulators for screenshots:"
echo ""
xcrun simctl list devices available | grep -E "(iPhone 17|iPhone 16|iPad Pro)"

echo ""
echo "======================================"
echo "SCREENSHOT CAPTURE INSTRUCTIONS"
echo "======================================"
echo ""
echo "1. Open Xcode and run the app on the target simulator"
echo "2. Navigate to each screen and capture with Cmd+S (from Simulator menu)"
echo "3. Or use the commands below:"
echo ""
echo "To capture a screenshot programmatically:"
echo "  xcrun simctl io booted screenshot ~/Desktop/screenshot.png"
echo ""
echo "To capture video (for App Preview):"
echo "  xcrun simctl io booted recordVideo ~/Desktop/preview.mp4"
echo ""
echo "======================================"
echo "RECOMMENDED SCREENSHOT SEQUENCE"
echo "======================================"
echo ""
echo "1. Dashboard - Show jobs today, revenue stats, quick tools"
echo "2. AI Estimator - Camera view with surface detection"
echo "3. Invoicing - Invoice detail view"
echo "4. Calendar - Month view with scheduled jobs"
echo "5. Chemical Calculator - Mixing calculator UI"
echo "6. Client List - CRM with client cards"
echo "7. Before/After Camera - Field tools"
echo "8. Business Analytics - Revenue charts"
echo ""
echo "======================================"
echo "DEVICE RESOLUTIONS"
echo "======================================"
echo ""
echo "iPhone 6.9\" (iPhone 17 Pro Max): 1320 x 2868 px"
echo "iPhone 6.7\" (iPhone 15 Pro Max): 1290 x 2796 px" 
echo "iPhone 6.5\": 1284 x 2778 px"
echo "iPad Pro 12.9\": 2048 x 2732 px"
echo ""

# Function to capture screenshot on running simulator
capture_screenshot() {
    local name=$1
    local device=$2
    local output_dir="$SCREENSHOTS_DIR/$device"
    local filename="${output_dir}/${name}_$(date +%Y%m%d_%H%M%S).png"
    
    xcrun simctl io booted screenshot "$filename"
    echo "✅ Captured: $filename"
}

# Interactive mode prompt
echo "Would you like to start interactive capture mode? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting interactive capture mode..."
    echo "Press Enter after navigating to each screen to capture."
    echo "Type 'quit' to exit."
    echo ""
    
    counter=1
    while true; do
        echo -n "Screen name (or 'quit'): "
        read -r screen_name
        
        if [[ "$screen_name" == "quit" ]]; then
            echo "Exiting capture mode."
            break
        fi
        
        xcrun simctl io booted screenshot "$SCREENSHOTS_DIR/${counter}_${screen_name}.png" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ Captured: ${counter}_${screen_name}.png"
            ((counter++))
        else
            echo "❌ Failed to capture. Is a simulator running?"
        fi
    done
fi

echo ""
echo "Done! Check your screenshots at: $SCREENSHOTS_DIR"
echo ""
echo "Next steps:"
echo "1. Add text overlays and device frames using Figma/Sketch"
echo "2. Export final screenshots at correct resolutions"
echo "3. Upload to App Store Connect"
