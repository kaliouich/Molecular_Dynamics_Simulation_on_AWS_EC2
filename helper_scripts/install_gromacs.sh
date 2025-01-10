#!/bin/bash

# Update the package list
sudo apt update

# Install dependencies
sudo apt install -y build-essential cmake git libfftw3-dev libgsl-dev libopenblas-dev

# Set the GROMACS version
VERSION="2023.2"

# Download GROMACS source code
wget https://git.science.uu.nl/gromacs/gromacs/archive/refs/tags/${VERSION}.tar.gz -O gromacs-${VERSION}.tar.gz

# Create a directory for GROMACS
mkdir gromacs-${VERSION}
# Extract the downloaded file into the new directory
tar -xzf gromacs-${VERSION}.tar.gz -C gromacs-${VERSION} --strip-components=1

# Change to the extracted directory
cd gromacs-${VERSION}/build

# Create a build directory
mkdir -p build
cd build

# Configure the build
cmake .. -DGMX_BUILD_OWN_FFTW=ON -DGMX_MPI=OFF -DGMX_DOUBLE=OFF

# Compile the source code
make -j $(nproc)

# Install GROMACS
sudo make install

# Source the GROMACS environment
source /usr/local/gromacs/5.0.7/bin/gmxrc

# Optional: Add GROMACS to your PATH permanently
echo "source /usr/local/gromacs/5.0.7/bin/gmxrc" >> ~/.bashrc 
echo 'export PATH=$PATH:/usr/local/gromacs/5.0.7/bin' >> ~/.bashrc 

# Source the updated .bashrc
source ~/.bashrc

# Clean up
cd ../../..
rm -rf gromacs-${VERSION} gromacs-${VERSION}.tar.gz

echo "GROMACS installation is complete."
