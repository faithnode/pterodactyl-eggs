#!/bin/bash
# @image debian:bookworm-slim

source ../../../scripts/prepare.sh
source ../../../scripts/timeout.sh

source ../../../scripts/install/paper-api.sh

install_paper_project velocity "$_INSTALL_VELOCITY_VERSION"
