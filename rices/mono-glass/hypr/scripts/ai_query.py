#!/usr/bin/env python3
import sys

# Check if at least one argument was passed
if len(sys.argv) < 2:
    print("No prompt provided!")
    sys.exit(1)

# Print the first argument
print(sys.argv[1])
