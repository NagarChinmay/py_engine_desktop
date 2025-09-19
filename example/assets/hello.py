print("🐍 Hello from Python!")
print("=" * 50)

import sys
import os

# Environment information
print(f"Python version: {sys.version.split()[0]}")
print(f"Python executable: {sys.executable}")
print(f"Working directory: {os.getcwd()}")

# Check if running in virtual environment
if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
    print("🔵 Running in VIRTUAL ENVIRONMENT")
    print(f"Virtual env prefix: {sys.prefix}")
else:
    print("🔘 Running in BASE Python environment")

print("=" * 50)

# Test some basic functionality
print("📊 Basic Python functionality test:")
for i in range(3):
    print(f"  Count: {i + 1}")

# Test package availability
print("\n📦 Testing package availability:")
packages_to_test = ['numpy', 'pandas', 'requests', 'matplotlib']

for package in packages_to_test:
    try:
        __import__(package)
        print(f"  ✅ {package} - Available")
    except ImportError:
        print(f"  ❌ {package} - Not installed")

print("\n🎉 Script completed successfully!")
print("=" * 50)