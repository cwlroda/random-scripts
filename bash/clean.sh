#!/bin/bash
# Free storage space script

# Clean apt cache
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove --purge

# Clean pip cache
pip3 cache purge

# Clean conda cache
conda clean --all
