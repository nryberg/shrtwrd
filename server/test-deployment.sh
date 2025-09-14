#!/bin/bash

# Test script for shrtwrd.com deployment
# Tests both IP direct access and domain name access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DROPLET_IP="167.172.193.225"
DOMAIN="shrtwrd.com"
SUBDOMAINS=("one" "two" "three" "four" "five")

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  shrtwrd.com Deployment Test${NC}"
echo -e "${BLUE}================================${NC}"

print_status() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

test_url() {
    local url="$1"
    local description="$2"
    local expected_pattern="$3"

    print_status "Testing: $description"
    echo "         URL: $url"

    if response=$(curl -s --connect-timeout 10 --max-time 30 "$url" 2>/dev/null); then
        if [[ -n "$expected_pattern" ]] && [[ ! "$response" =~ $expected_pattern ]]; then
            print_error "Response doesn't match expected pattern"
            echo "         Expected pattern: $expected_pattern"
            echo "         Got: ${response:0:100}..."
            return 1
        else
            print_success "Response received (${#response} characters)"
            echo "         Response: ${response:0:50}..."
            return 0
        fi
    else
        print_error "Failed to connect or get response"
        return 1
    fi
}

check_dns() {
    local hostname="$1"
    print_status "Checking DNS for $hostname"

    if resolved_ip=$(nslookup "$hostname" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}'); then
        if [[ "$resolved_ip" == "$DROPLET_IP" ]]; then
            print_success "DNS resolves correctly to $resolved_ip"
            return 0
        else
            print_error "DNS resolves to $resolved_ip, expected $DROPLET_IP"
            return 1
        fi
    else
        print_error "DNS resolution failed"
        return 1
    fi
}

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0

run_test() {
    local test_function="$1"
    shift
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if "$test_function" "$@"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    fi
    echo
}

echo -e "${YELLOW}Phase 1: Direct IP Testing${NC}"
echo "Testing direct connection to droplet..."
echo

# Test direct IP access
run_test test_url "http://$DROPLET_IP" "Direct IP access" "^[a-z]+-[a-z]+-[a-z]+$"
run_test test_url "http://$DROPLET_IP/5" "Direct IP access (5 lines)" ""
run_test test_url "http://$DROPLET_IP/1" "Direct IP access (1 line)" "^[a-z]+-[a-z]+-[a-z]+$"

echo -e "${YELLOW}Phase 2: DNS Resolution Testing${NC}"
echo "Checking if domains resolve to correct IP..."
echo

# Test DNS resolution
run_test check_dns "$DOMAIN"
for subdomain in "${SUBDOMAINS[@]}"; do
    run_test check_dns "$subdomain.$DOMAIN"
done

echo -e "${YELLOW}Phase 3: Domain Access Testing${NC}"
echo "Testing access via domain names..."
echo

# Test domain access (only if DNS works)
if nslookup "$DOMAIN" >/dev/null 2>&1; then
    run_test test_url "http://$DOMAIN" "Root domain (3 words)" "^[a-z]+-[a-z]+-[a-z]+$"
    run_test test_url "http://$DOMAIN/5" "Root domain (5 lines)" ""

    # Test subdomains
    run_test test_url "http://one.$DOMAIN" "One word subdomain" "^[a-z]+$"
    run_test test_url "http://two.$DOMAIN" "Two words subdomain" "^[a-z]+-[a-z]+$"
    run_test test_url "http://three.$DOMAIN" "Three words subdomain" "^[a-z]+-[a-z]+-[a-z]+$"
    run_test test_url "http://four.$DOMAIN" "Four words subdomain" "^[a-z]+-[a-z]+-[a-z]+-[a-z]+$"
    run_test test_url "http://five.$DOMAIN" "Five words subdomain" "^[a-z]+-[a-z]+-[a-z]+-[a-z]+-[a-z]+$"

    # Test subdomain with multiple lines
    run_test test_url "http://two.$DOMAIN/3" "Two words, 3 lines" ""
    run_test test_url "http://four.$DOMAIN/2" "Four words, 2 lines" ""
else
    print_error "Skipping domain tests - DNS not configured yet"
    echo "         Set up your DNS records first (see DNS-SETUP.md)"
fi

echo -e "${YELLOW}Phase 4: Error Handling Testing${NC}"
echo "Testing error conditions..."
echo

# Test error conditions
run_test test_url "http://$DROPLET_IP/101" "Invalid line count (>100)" "Number of lines must be between 1 and 100"
run_test test_url "http://$DROPLET_IP/invalid" "Invalid path" "Invalid path"

echo -e "${YELLOW}Phase 5: Server Health Check${NC}"
print_status "Checking server response time and consistency"

# Test response time
start_time=$(date +%s%N)
test_url "http://$DROPLET_IP" "Response time test" "" >/dev/null 2>&1
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))

if [[ $response_time -lt 1000 ]]; then
    print_success "Response time: ${response_time}ms (excellent)"
elif [[ $response_time -lt 3000 ]]; then
    print_success "Response time: ${response_time}ms (good)"
else
    print_error "Response time: ${response_time}ms (slow)"
fi

# Test multiple requests for consistency
print_status "Testing response consistency (5 requests)"
consistent=true
for i in {1..5}; do
    response=$(curl -s "http://$DROPLET_IP" 2>/dev/null || echo "ERROR")
    if [[ "$response" == "ERROR" ]] || [[ ! "$response" =~ ^[a-z]+-[a-z]+-[a-z]+$ ]]; then
        consistent=false
        break
    fi
done

if $consistent; then
    print_success "All responses consistent and valid"
else
    print_error "Inconsistent responses detected"
fi

echo
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}      Test Results Summary${NC}"
echo -e "${BLUE}================================${NC}"

if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
    print_success "All tests passed! ($PASSED_TESTS/$TOTAL_TESTS)"
    echo -e "${GREEN}Your shrtwrd.com server is fully operational!${NC}"
else
    print_error "Some tests failed ($PASSED_TESTS/$TOTAL_TESTS passed)"

    if ! nslookup "$DOMAIN" >/dev/null 2>&1; then
        echo
        echo -e "${YELLOW}DNS Issues Detected:${NC}"
        echo "• Configure your DNS records with Hover (see DNS-SETUP.md)"
        echo "• Wait 5-60 minutes for DNS propagation"
        echo "• Then run this test again"
    fi
fi

echo
echo -e "${BLUE}Server Information:${NC}"
echo "• Droplet IP: $DROPLET_IP"
echo "• Domain: $DOMAIN"
echo "• Container Status: $(ssh root@$DROPLET_IP 'docker ps -f name=shrtwrd-server --format "{{.Status}}"' 2>/dev/null || echo "Unable to check")"

echo
echo -e "${BLUE}Quick Commands:${NC}"
echo "• View logs: ssh root@$DROPLET_IP 'docker logs shrtwrd-server'"
echo "• Restart container: ssh root@$DROPLET_IP 'docker restart shrtwrd-server'"
echo "• Check DNS: nslookup $DOMAIN"
echo "• Test manually: curl http://$DROPLET_IP"

if [[ $PASSED_TESTS -lt $TOTAL_TESTS ]]; then
    exit 1
fi
