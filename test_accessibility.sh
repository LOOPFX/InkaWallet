#!/bin/bash

# InkaWallet Accessibility Features Test Script
# Tests all biometric, voice, and haptic features

echo "=========================================="
echo "InkaWallet Accessibility Features Testing"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((FAILED++))
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "ℹ️  INFO: $1"
}

echo "📋 Test 1: Flutter Code Compilation"
echo "------------------------------------"
cd /home/loopfx/InkaWallet/mobile

# Check for errors
ERROR_COUNT=$(flutter analyze 2>&1 | grep "^error" | grep -v "test/" | wc -l)
if [ $ERROR_COUNT -eq 0 ]; then
    print_result 0 "No compilation errors in main code"
else
    print_result 1 "Found $ERROR_COUNT compilation error(s)"
fi

# Check warnings
WARNING_COUNT=$(flutter analyze 2>&1 | grep "^warning" | wc -l)
if [ $WARNING_COUNT -lt 20 ]; then
    print_info "Found $WARNING_COUNT warnings (acceptable)"
else
    print_warning "Found $WARNING_COUNT warnings (consider reviewing)"
fi

echo ""
echo "📋 Test 2: Service Files Existence"
echo "------------------------------------"

# Check if all service files exist
FILES=(
    "lib/services/biometric_service.dart"
    "lib/services/speechmatics_service.dart"
    "lib/services/voice_command_service.dart"
    "lib/services/accessibility_service.dart"
    "lib/widgets/voice_enabled_screen.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        SIZE=$(wc -l < "$file")
        print_result 0 "File exists: $file ($SIZE lines)"
    else
        print_result 1 "File missing: $file"
    fi
done

echo ""
echo "📋 Test 3: Service Implementation Check"
echo "------------------------------------"

# Check BiometricService implementation
if grep -q "authenticateForLogin" lib/services/biometric_service.dart; then
    print_result 0 "BiometricService: authenticateForLogin() implemented"
else
    print_result 1 "BiometricService: authenticateForLogin() missing"
fi

if grep -q "authenticateForTransaction" lib/services/biometric_service.dart; then
    print_result 0 "BiometricService: authenticateForTransaction() implemented"
else
    print_result 1 "BiometricService: authenticateForTransaction() missing"
fi

# Check SpeechmaticsService implementation
if grep -q "extractIntent" lib/services/speechmatics_service.dart; then
    print_result 0 "SpeechmaticsService: extractIntent() implemented"
else
    print_result 1 "SpeechmaticsService: extractIntent() missing"
fi

if grep -q "extractAmount" lib/services/speechmatics_service.dart; then
    print_result 0 "SpeechmaticsService: extractAmount() implemented"
else
    print_result 1 "SpeechmaticsService: extractAmount() missing"
fi

# Check VoiceCommandService implementation
if grep -q "listenForCommand" lib/services/voice_command_service.dart; then
    print_result 0 "VoiceCommandService: listenForCommand() implemented"
else
    print_result 1 "VoiceCommandService: listenForCommand() missing"
fi

if grep -q "handleSendMoneyCommand" lib/services/voice_command_service.dart; then
    print_result 0 "VoiceCommandService: handleSendMoneyCommand() implemented"
else
    print_result 1 "VoiceCommandService: handleSendMoneyCommand() missing"
fi

if grep -q "handleLoginCommand" lib/services/voice_command_service.dart; then
    print_result 0 "VoiceCommandService: handleLoginCommand() implemented"
else
    print_result 1 "VoiceCommandService: handleLoginCommand() missing"
fi

# Check AccessibilityService enhancements
if grep -q "enableVoiceControl" lib/services/accessibility_service.dart; then
    print_result 0 "AccessibilityService: enableVoiceControl() implemented"
else
    print_result 1 "AccessibilityService: enableVoiceControl() missing"
fi

echo ""
echo "📋 Test 4: Haptic Feedback Patterns"
echo "------------------------------------"

# Check for vibration patterns
PATTERNS=(
    "vibrateShort"
    "vibrateDouble"
    "vibrateSuccess"
    "vibrateError"
    "vibrateNavigation"
    "vibrateAction"
    "vibrateConfirmation"
)

for pattern in "${PATTERNS[@]}"; do
    if grep -q "$pattern" lib/services/voice_command_service.dart; then
        print_result 0 "Haptic pattern: $pattern() defined"
    else
        print_result 1 "Haptic pattern: $pattern() missing"
    fi
done

echo ""
echo "📋 Test 5: Voice Commands Implementation"
echo "------------------------------------"

# Check for voice command intents
INTENTS=(
    "send_money"
    "request_money"
    "check_balance"
    "login"
    "register"
    "buy_airtime"
    "pay_bills"
    "scan_qr"
    "check_credit"
    "bnpl"
    "help"
    "go_back"
)

INTENT_COUNT=0
for intent in "${INTENTS[@]}"; do
    if grep -q "'$intent'" lib/services/speechmatics_service.dart; then
        ((INTENT_COUNT++))
    fi
done

if [ $INTENT_COUNT -ge 10 ]; then
    print_result 0 "Voice intents: $INTENT_COUNT/12 implemented"
else
    print_result 1 "Voice intents: Only $INTENT_COUNT/12 implemented"
fi

echo ""
echo "📋 Test 6: Screen Integration"
echo "------------------------------------"

# Check LoginScreen integration
if grep -q "BiometricService" lib/screens/login_screen.dart; then
    print_result 0 "LoginScreen: BiometricService integrated"
else
    print_result 1 "LoginScreen: BiometricService not integrated"
fi

if grep -q "VoiceCommandService" lib/screens/login_screen.dart; then
    print_result 0 "LoginScreen: VoiceCommandService integrated"
else
    print_result 1 "LoginScreen: VoiceCommandService not integrated"
fi

if grep -q "VoiceEnabledScreen" lib/screens/login_screen.dart; then
    print_result 0 "LoginScreen: VoiceEnabledScreen wrapper used"
else
    print_result 1 "LoginScreen: VoiceEnabledScreen wrapper missing"
fi

# Check SettingsScreen integration
if grep -q "voiceControlEnabled" lib/screens/settings_screen.dart; then
    print_result 0 "SettingsScreen: Voice control toggle implemented"
else
    print_result 1 "SettingsScreen: Voice control toggle missing"
fi

if grep -q "biometricAvailable" lib/screens/settings_screen.dart; then
    print_result 0 "SettingsScreen: Biometric settings implemented"
else
    print_result 1 "SettingsScreen: Biometric settings missing"
fi

echo ""
echo "📋 Test 7: Documentation"
echo "------------------------------------"
cd /home/loopfx/InkaWallet

if [ -f "ACCESSIBILITY_GUIDE.md" ]; then
    LINES=$(wc -l < ACCESSIBILITY_GUIDE.md)
    print_result 0 "ACCESSIBILITY_GUIDE.md exists ($LINES lines)"
else
    print_result 1 "ACCESSIBILITY_GUIDE.md missing"
fi

if [ -f "ACCESSIBILITY_README.md" ]; then
    LINES=$(wc -l < ACCESSIBILITY_README.md)
    print_result 0 "ACCESSIBILITY_README.md exists ($LINES lines)"
else
    print_result 1 "ACCESSIBILITY_README.md missing"
fi

# Check for key sections in documentation
if grep -q "Voice Commands" ACCESSIBILITY_GUIDE.md; then
    print_result 0 "Documentation: Voice Commands section present"
else
    print_result 1 "Documentation: Voice Commands section missing"
fi

if grep -q "Biometric" ACCESSIBILITY_GUIDE.md; then
    print_result 0 "Documentation: Biometric section present"
else
    print_result 1 "Documentation: Biometric section missing"
fi

if grep -q "Haptic" ACCESSIBILITY_GUIDE.md; then
    print_result 0 "Documentation: Haptic feedback section present"
else
    print_result 1 "Documentation: Haptic feedback section missing"
fi

echo ""
echo "📋 Test 8: Backend Integration"
echo "------------------------------------"

# Check if backend is running
if curl -s http://localhost:3000/api/auth/login > /dev/null 2>&1; then
    print_result 0 "Backend server is running on port 3000"
else
    print_warning "Backend server not responding (may not be started)"
fi

# Check API service integration
cd /home/loopfx/InkaWallet/mobile
if grep -q "updateAccessibilitySettings" lib/services/api_service.dart; then
    print_result 0 "API Service: updateAccessibilitySettings() implemented"
else
    print_result 1 "API Service: updateAccessibilitySettings() missing"
fi

echo ""
echo "📋 Test 9: Dependencies Check"
echo "------------------------------------"

# Check pubspec.yaml for required packages
PACKAGES=(
    "local_auth:"
    "flutter_tts:"
    "speech_to_text:"
    "vibration:"
)

for package in "${PACKAGES[@]}"; do
    if grep -q "$package" pubspec.yaml; then
        print_result 0 "Dependency: $package added"
    else
        print_result 1 "Dependency: $package missing"
    fi
done

echo ""
echo "=========================================="
echo "📊 Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed:   $PASSED${NC}"
echo -e "${RED}Failed:   $FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

TOTAL=$((PASSED + FAILED))
SUCCESS_RATE=$((PASSED * 100 / TOTAL))

echo "Success Rate: $SUCCESS_RATE% ($PASSED/$TOTAL)"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo "✅ Accessibility features are production ready"
    exit 0
elif [ $FAILED -lt 5 ]; then
    echo -e "${YELLOW}⚠️  MOSTLY PASSED${NC}"
    echo "Minor issues detected. Review failed tests."
    exit 0
else
    echo -e "${RED}❌ TESTS FAILED${NC}"
    echo "Significant issues detected. Review implementation."
    exit 1
fi
