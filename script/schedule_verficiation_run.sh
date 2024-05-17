#!/bin/bash
# Copyright 2024 (c) SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Schedule a verification run for a os-autoinst PR
# USAGE:
#
# schedule_verification_run $SOURCE $PR_ID $BASE_TEST_ID $[test/module, test/module, ...] $TEST_NAME
#
# Parameters
#
# * $SOURCE - The source you want to schedule a rund for. Can be either opensuse or suse.
# * $PR_ID - The ID of your GitHub Pull Request.
# * $BASE_TEST_ID - The ID of the test you want you use as a base.
# * $[test/module, ...] - The modules of your test you want to schedule for.
# * $TEST_NAME - The Name of your test. (E.g.: TETS=RUST)
#
# Specify your GitHub access token in a config file at '~/.config/openqa/gh.conf' like this:
#
# ```
# GH_ACCESS_TOKEN="YOUR_TOKEN_HERE"
# ```
#
# Default test modules
#
# The following modules are automatically selected to load for your run:
#
# * 'tests/installation/bootloader_start'
# * 'tests/boot/boot_to_desktop'
# 
# Example
#
# Pass arguments to this script like this:
#
# schedule_verification_run opensuse TOKEN 1234 12345 tests/console/rustup,tests/console/cargo RUST


help_text=$(cat <<'EOF'
OpenQA verification run scheduler.

USAGE:
======

$ schedule_verification_run \$SOURCE \$PR_ID \$BASE_TEST_ID \$[test/module, test/module,...] \$TEST_NAME

Parameters
----------

* \$SOURCE - The source you want to schedule a rund for. Can be either opensuse or suse.
* \$PR_ID - The ID of your GitHub Pull Request.
* \$BASE_TEST_ID - The ID of the test you want you use as a base.
* \$[test/module,...] - The modules of your test you want to schedule for.
* \$TEST_NAME - The Name of your test. (E.g.: TEST=RUST)

Specify your GitHub access token in '~/.config/openqa/gh.conf' like this:

```
GH_ACCESS_TOKEN="YOUR_TOKEN_HERE"
```

Default test modules
--------------------

The following modules are automatically selected to load for your run:

* 'tests/installation/bootloader_start'
* 'tests/boot/boot_to_desktop'

Options
-------

* '-h' / '--help' - Display this help text.

EOF
)

source="$1"
pr_id="$2"
test_id="$3"
modules="$4"
test_name="$5"

config_file="$HOME/.config/openqa/gh.conf"
config=""

# See help text.
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "$help_text"
  exit 0
fi

# If too few or too many arguments are supplied -> die.
if [ "$#" -ne 5 ]; then
  echo "Invalid number of arguments. Run with '-h' or '--help' to view usage."
  exit 1
fi

# Read GH token from config file.
if [[ -f "$config_file" ]]; then
  config=$(grep "^GH_ACCESS_TOKEN=" "$config_file" | cut -d'"' -f2)
else
  echo "No GitHub token file found! Run with '-h' for more info."
  exit 1
fi

GITHUB_TOKEN=$config

export GITHUB_TOKEN

if [ "$source" = "opensuse" ]; then
  echo "Dispatching verification run for opensuse..."
  openqa-clone-custom-git-refspec "https://github.com/os-autoinst/os-autoinst-distri-opensuse/pull/$pr_id" \
    "https://openqa.opensuse.org/tests/$test_id" \
    SCHEDULE="tests/installation/bootloader_start,tests/boot/boot_to_desktop,$modules" \
    TEST="$test_name"
elif [ "$source" = "suse" ]; then
  echo "Dispatching verification run for suse..."
  openqa-clonse-custom-git-refspec "https://github.com/os-autoinst-distri-opensuse/pull/$pr_id" \
    "https://openqa.suse.de/tests/$test_id" \
    SCHEDULE="tests/installation/bootloader_start,tests/boot/boot_to_desktop,$modules" \
    TEST="$test_name"
else
  # NOTE: Technically we could support custom targets via a config file. TBI.
  echo "Unknown argument '$1'. Must be either 'suse' or 'opensuse'. Custom openqa instances not yet supported."
  exit 1
fi
