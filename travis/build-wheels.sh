
#!/bin/bash
set -e -u -x

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
         auditwheel repair "$wheel" --plat "$PLAT" -w /io/wheelhouse/
    fi
}
#apt-get install
#curl https://raw.githubusercontent.com/dvershinin/apt-get-centos/master/apt-get.sh -o /usr/local/bin/apt-get
#chmod 0755 /usr/local/bin/apt-get

yum install -y wget
yum install -y eigen3-devel

cd /home && git clone https://github.com/xianyi/OpenBLAS/ && cd OpenBLAS && USE_THREAD=0 make -j && make PREFIX=/usr/local install


cd /home
wget https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz
tar xzf v2.2.2.tar.gz
cd gflags-2.2.2 && mkdir build && cd build
cmake ../ -DBUILD_SHARED_LIBS=ON && make -j && make install

cd /home
git clone https://github.com/google/glog.git
cd glog && mkdir build && cd build
cmake ../ -DBUILD_SHARED_LIBS=ON && make -j && make install

#rocksdb dependencies
yum install -y centos-release-scl
yum install -y snappy snappy-devel
yum install -y zlib zlib-devel
yum install -y bzip2 bzip2-devel
yum install -y lz4-devel
yum install -y libzstd

#rocksdb
cd /home && git clone https://github.com/facebook/rocksdb.git && cd rocksdb && git checkout v5.9.2 && \
    DEBUG_LEVEL=0 CXXFLAGS='-Wno-error=deprecated-copy -Wno-error=pessimizing-move -Wno-error=class-memaccess' make -j shared_lib  && \
    DEBUG_LEVEL=0 CXXFLAGS='-Wno-error=deprecated-copy -Wno-error=pessimizing-move -Wno-error=class-memaccess' make install

#rapidjson
cd /home && git clone https://github.com/Tencent/rapidjson.git && cd rapidjson && mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make -j && make install

# openimageio
cd /home
yum install -y libpng-devel
#yum install -y libtiff-devel
git clone https://github.com/vadz/libtiff.git
cd libtiff && ./configure && make -j && make install

cd /home
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
cd libjpeg-turbo/
cmake -G"Unix Makefiles" -DWITH_JPEG8=1 . && make -j && make install && yum install -y libjpeg-devel

cd /home
git clone https://github.com/AcademySoftwareFoundation/openexr
cd openexr && git checkout v2.5.5 && mkdir build && cd build && cmake .. && make -j && make install

cd /home
git clone https://github.com/AcademySoftwareFoundation/Imath.git
cd Imath && mkdir build  && cd build && cmake .. && make -j && make install

#boost c++ library
cd /home
wget https://sourceforge.net/projects/boost/files/boost/1.61.0/boost_1_61_0.tar.gz
tar -xf boost_1_61_0.tar.gz && cd boost_1_61_0 && ./bootstrap.sh && ./b2 install

#openimageio
cd /home
git clone https://github.com/ZJCRT/oiio && cd oiio && git checkout Release-1.6.18 && \ 
mkdir -p release && cd release/ && \ 
cmake ../ -DSTOP_ON_WARNING=OFF -DUSE_OPENCV=0 -DOIIO_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DUSE_PYTHON=OFF -DUSE_PYTHON3=OFF -DUSE_FFMPEG=OFF -DUSE_OPENGL=OFF -DOIIO_BUILD_CPP11=ON -DCMAKE_CXX_FLAGS=-isystem /opt/libjpeg-turbo/include && \
make -j​​​ && make install && cd /home && rm -fr oiio

# Build Ceres
cd /home
wget https://github.com/ceres-solver/ceres-solver/archive/refs/tags/1.14.0.zip &&  \
unzip 1.14.0.zip && \
cd ceres-solver-1.14.0/​​​​​​​​ && \
mkdir build && \
cd build && \
cmake  ../ \
-DCXX11=ON \
-DBUILD_DOCUMENTATION=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DBUILD-BENCHMARKS=OFF -DEIGENSPARSE=ON -DSUITESPARSE=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release 
make -j​​​​ && \
make install && \
cd /home && rm -rf 1.14.0​​​​​​​​.zip && \
rm -rf ceres-solver-1.14.0

cd /
# Compile wheels
for PYBIN in /opt/python/*/bin; do
    "${PYBIN}/pip" install -r dev-requirenebts.txt
    "${PYBIN}/pip" wheel --no-deps -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

# Install packages and test
for PYBIN in /opt/python/*/bin/; do
    "${PYBIN}/pip" install pytheia --no-index -f /io/wheelhouse
    (cd "$HOME"; "${PYBIN}/nosetests" pytheia)
done
