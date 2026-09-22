#!/bin/bash
# @image debian:bookworm-slim

source ../../../scripts/prepare.sh
source ../../../scripts/timeout.sh

source ../../../scripts/install/paper-api.sh

install_paper_project waterfall "$_INSTALL_WATERFALL_VERSION"
