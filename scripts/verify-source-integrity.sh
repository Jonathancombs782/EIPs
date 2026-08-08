#!/bin/bash

##
# Source Code Integrity Verification Script
# 
# This script verifies the integrity of source code in the repository by:
# 1. Generating and comparing file checksums
# 2. Verifying critical files haven't been tampered with
# 3. Checking for unauthorized files
# 4. Validating file permissions
#
# Usage: ./verify-source-integrity.sh [--strict] [--generate] [--output FILE]
##

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECKSUMS_FILE="${REPO_ROOT}/.checksums"
STRICT_MODE=false
GENERATE_MODE=false
OUTPUT_FILE=""
TEMP_DIR=$(mktemp -d)

trap "rm -rf $TEMP_DIR" EXIT

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --strict)
      STRICT_MODE=true
      shift
      ;;
    --generate)
      GENERATE_MODE=true
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Critical files to verify (should never be deleted)
declare -a CRITICAL_FILES=(
  ".github/CODEOWNERS"
  ".github/workflows/ci.yml"
  ".github/workflows/enforce-signed-commits.yml"
  "config/eipw.toml"
  "CONTRIBUTING.md"
  "LICENSE.md"
  "README.md"
  "_config.yml"
)

# Files/directories to exclude from scanning
declare -a EXCLUSIONS=(
  ".git"
  ".github"
  "node_modules"
  ".bundle"
  "_site"
  ".DS_Store"
  "*.swp"
  "*.swo"
  "*~"
)

# Generate exclusion pattern for find command
EXCLUDE_PATTERN=""
for excl in "${EXCLUSIONS[@]}"; do
  EXCLUDE_PATTERN="${EXCLUDE_PATTERN} -not -path \"*/${excl}/*\" -not -name \"${excl}\""
done

# Generate checksums for critical files
generate_checksums() {
  echo "Generating checksums for critical files..."
  
  local checksum_data=""
  
  for file in "${CRITICAL_FILES[@]}"; do
    local filepath="${REPO_ROOT}/${file}"
    if [ -f "$filepath" ]; then
      local sha256=$(sha256sum "$filepath" | cut -d' ' -f1)
      checksum_data="${checksum_data}${file}:${sha256}\n"
      log_success "Checksummed: $file"
    else
      log_warning "File not found: $file"
    fi
  done
  
  # Generate checksums for all source files
  echo "Generating checksums for source files..."
  find "$REPO_ROOT/EIPS" -type f -name "*.md" 2>/dev/null | while read file; do
    local sha256=$(sha256sum "$file" | cut -d' ' -f1)
    local rel_path="${file#$REPO_ROOT/}"
    checksum_data="${checksum_data}${rel_path}:${sha256}\n"
  done
  
  # Save checksums
  if [ -n "$OUTPUT_FILE" ]; then
    echo -e "$checksum_data" > "$OUTPUT_FILE"
    log_success "Checksums saved to: $OUTPUT_FILE"
  else
    echo -e "$checksum_data" > "$CHECKSUMS_FILE"
    log_success "Checksums saved to: $CHECKSUMS_FILE"
  fi
}

# Verify checksums
verify_checksums() {
  local checksum_file="${OUTPUT_FILE:-$CHECKSUMS_FILE}"
  
  if [ ! -f "$checksum_file" ]; then
    log_error "Checksums file not found: $checksum_file"
    log_error "Generate checksums first with: $0 --generate"
    exit 1
  fi
  
  echo "Verifying file integrity..."
  
  local mismatches=0
  local verified=0
  
  while IFS=':' read -r file expected_sha; do
    local filepath="${REPO_ROOT}/${file}"
    
    if [ ! -f "$filepath" ]; then
      log_error "File missing: $file"
      ((mismatches++))
      continue
    fi
    
    local actual_sha=$(sha256sum "$filepath" | cut -d' ' -f1)
    
    if [ "$actual_sha" != "$expected_sha" ]; then
      log_error "Checksum mismatch: $file"
      echo "  Expected: $expected_sha"
      echo "  Actual:   $actual_sha"
      ((mismatches++))
    else
      log_success "Verified: $file"
      ((verified++))
    fi
  done < "$checksum_file"
  
  echo ""
  echo "Summary: $verified verified, $mismatches mismatches"
  
  if [ $mismatches -gt 0 ]; then
    if [ "$STRICT_MODE" = true ]; then
      log_error "Integrity check failed in strict mode!"
      exit 1
    else
      log_warning "Integrity issues detected. Review before proceeding."
      exit 0
    fi
  fi
  
  log_success "All files verified successfully!"
}

# Verify critical files exist
verify_critical_files() {
  echo "Verifying critical files exist..."
  
  local missing=0
  
  for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "${REPO_ROOT}/${file}" ]; then
      log_success "Found: $file"
    else
      log_error "Missing: $file"
      ((missing++))
    fi
  done
  
  if [ $missing -gt 0 ]; then
    log_error "Missing $missing critical files!"
    if [ "$STRICT_MODE" = true ]; then
      exit 1
    fi
  else
    log_success "All critical files present"
  fi
}

# Scan for unauthorized files
scan_for_unauthorized() {
  echo "Scanning for unauthorized files..."
  
  local suspicious=0
  
  # Look for suspicious file types in EIPS directory
  while IFS= read -r file; do
    if [[ "$file" =~ \.(exe|dll|so|sh|py|js|zip|tar|gz)$ ]]; then
      if [ ! "$file" == "*.sh" ]; then
        log_warning "Suspicious file type: $file"
        ((suspicious++))
      fi
    fi
  done < <(find "$REPO_ROOT/EIPS" -type f 2>/dev/null)
  
  if [ $suspicious -gt 0 ]; then
    log_warning "Found $suspicious potentially suspicious files"
  else
    log_success "No suspicious files detected"
  fi
}

# Check file permissions
check_permissions() {
  echo "Checking file permissions..."
  
  # Critical files should not be world-writable
  for file in "${CRITICAL_FILES[@]}"; do
    local filepath="${REPO_ROOT}/${file}"
    if [ -f "$filepath" ]; then
      local perms=$(stat -c %a "$filepath" 2>/dev/null || stat -f %OLp "$filepath")
      
      # Check if world-writable
      if [[ "$perms" == *2 ]] || [[ "$perms" == *6 ]] || [[ "$perms" == *7 ]]; then
        log_error "File is world-writable: $file ($perms)"
      else
        log_success "Permissions OK: $file ($perms)"
      fi
    fi
  done
}

# Main
main() {
  echo "=========================================="
  echo "Source Code Integrity Verification"
  echo "=========================================="
  echo ""
  
  if [ "$GENERATE_MODE" = true ]; then
    generate_checksums
  else
    verify_critical_files
    verify_checksums
    scan_for_unauthorized
    check_permissions
    echo ""
    log_success "Integrity verification completed"
  fi
}

main "$@"
