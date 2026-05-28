#!/bin/bash
# Security hardening script - Remove unnecessary packages and clean up
set -e

echo "========================================="
echo "WSO2 MI Base Image Hardening"
echo "========================================="

echo "→ Removing unnecessary packages..."
apt-get purge -y --auto-remove \
  wget \
  netcat-traditional \
  telnet \
  ftp \
  2>/dev/null || true

echo "→ Cleaning up package cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "→ Removing unnecessary files..."
# Remove documentation
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*
rm -rf /usr/share/info/*

# Remove caches
rm -rf /var/cache/*

echo "✓ Security hardening complete"
echo "========================================="
