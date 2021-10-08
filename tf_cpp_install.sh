#!/bin/bash
# Master installation script for Tensorflow 1.14.x (C++ API)

R_FLAG=false

print_help() {
    echo "Options:"
    echo "-h    Show help"
    echo "-r    Reinstall dependencies"
}

while getopts 'hr' FLAG; do
    case "${FLAG}" in
        h) print_help
        exit 1 ;;
        r) R_FLAG=true ;;
        *) print_help
        exit 1 ;;
    esac
done

read -s -p "Enter password for [sudo]: " sudoPW

START=$(date +%s.%N)

if [ ! -d deps ]; then
    mkdir deps
fi
cd deps

echo $sudoPW | sudo -S apt-get update && sudo -S apt-get upgrade -y


###--- BAZEL 0.24.1 ---###

BAZEL_VER=`bazel version | grep "Build label" | awk '{print $3}'`

if [[ $BAZEL_VER != "0.24.1" ]]; then
    if [ ! -f bazel-0.24.1-installer-linux-x86_64.sh ]
    then
        wget https://github.com/bazelbuild/bazel/releases/download/0.24.1/bazel-0.24.1-installer-linux-x86_64.sh
    fi
    
    chmod u+x bazel-0.24.1-installer-linux-x86_64.sh
    ./bazel-0.24.1-installer-linux-x86_64.sh
fi

bazel version

echo $sudoPW | sudo -S apt-get install -y build-essential curl git cmake unzip autoconf autogen automake libtool mlocate zlib1g-dev gcc-7 g++-7 wget
echo $sudoPW | sudo -S apt-get install -y python python3 python3-numpy python3-dev python3-pip python3-wheel
echo $sudoPW | sudo -S apt-get install -y python3.6 python3.6-dev
echo $sudoPW | sudo -S updatedb

echo $sudoPW | sudo -S update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
echo $sudoPW | sudo -S update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100


###--- TF 1.14.0 ---###

if [ ! -d tensorflow ]; then
    git clone https://github.com/tensorflow/tensorflow.git
fi

cd tensorflow
git checkout v1.14.0

echo "Replacing broken Eigen URLs..."
find . -type f -exec sed -i 's/http.*bitbucket.org\/eigen\/eigen\/get/https:\/\/storage.googleapis.com\/mirror.tensorflow.org\/bitbucket.org\/eigen\/eigen\/get/g' {} \;
EIGEN_COUNT=`grep -nr "https://storage.googleapis.com/mirror.tensorflow.org/bitbucket.org/eigen/eigen/get/" | wc -l`

if [ $EIGEN_COUNT -ne 6 ]; then
    echo "Eigen URLs not updated!"
    echo "Please manually replace all occurrences of"
    echo "http.*bitbucket.org/eigen/eigen/get"
    echo "with"
    echo "https://storage.googleapis.com/mirror.tensorflow.org/bitbucket.org/eigen/eigen/get"
    exit 1
fi

chmod u+x tensorflow/contrib/makefile/download_dependencies.sh
./tensorflow/contrib/makefile/download_dependencies.sh


###--- PROTOBUF 3.7.1 ---###

cd tensorflow/contrib/makefile/downloads/protobuf
git submodule update --init --recursive
./autogen.sh
./configure
make -j$(nproc)
make check -j$(nproc)

echo $sudoPW | sudo -S make install
echo $sudoPW | sudo -S ldconfig
cd ../../../../..


###--- FULL COMPILATION ---###

/usr/bin/gcc-7 --version
GCC_PATH=`which gcc-7`

/usr/bin/python3.6 --version
PYTHON_PATH=`which python3.6`
echo $PYTHON_PATH

# Manually update CUDA compute capability if error is thrown
CUDA_COMPUTE=""

if [[ ! -d /usr/local/cuda/samples/1_Utilities/deviceQuery && $CUDA_COMPUTE == ""]]; then
    cd /usr/local/cuda/samples/1_Utilities/deviceQuery
    sudo make
    CUDA_COMPUTE=`./deviceQuery | grep Capability | awk '{print $6}'`
else
    echo "Please download CUDA samples to determine CUDA compute capability for your GPU, or"
    echo "Manually update the CUDA_COMPUTE variable in the install script with your capability version"
    echo "This can be found at https://developer.nvidia.com/cuda-gpus#compute"
    exit 1
fi

CONFIG="${PYTHON_PATH}\n\nn\nn\nn\ny\ny\n${CUDA_COMPUTE}\nn\n${GCC_PATH}\nn\n\n"
printf ${CONFIG} | ./configure

bazel build --config=opt //tensorflow:libtensorflow_cc.so //tensorflow:install_headers


###--- Install shared libraries and headers ---###

if [[ $R_FLAG || -d /usr/local/tensorflow ]]; then
    echo $sudoPW | sudo -S rm -rf /usr/local/tensorflow
fi

echo $sudoPW | sudo -S mkdir /usr/local/tensorflow
echo $sudoPW | sudo -S cp -r bazel-genfiles/tensorflow/include/ /usr/local/tensorflow/
echo $sudoPW | sudo -S cp -r /usr/local/include/google/ /usr/local/tensorflow/include/
echo $sudoPW | sudo -S mkdir /usr/local/tensorflow/lib
echo $sudoPW | sudo -S cp -r bazel-bin/tensorflow/* /usr/local/tensorflow/lib
cd ../..

make -j$(nproc) M3DFXOffline

if [ -f Build/x64/Release/3DFX/M3DFXOffline ]; then
    echo "Installation Success!"
else
    echo "Installation Failed!"
    exit 1
fi

DURATION=$(echo "$(date +%s.%N) - ${START}" | bc)
echo "Script Execution Time: ${DURATION} seconds"
exit 0
