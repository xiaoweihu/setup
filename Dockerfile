FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu14.04

WORKDIR /app
ADD requirements.txt /app
ADD .tmux.conf /app
ADD .vimrc_customize_template /app
ADD .vimrc_plugin_template /app
ADD generate_vimrc.py /app

RUN apt-get update && apt-get install -y \
        bc \
        build-essential \
        cmake \
        gdb \
        git \
        gfortran \
        libboost-all-dev \
        libleveldb-dev \
        libopencv-dev \
        libopenblas-dev \
        libprotobuf-dev \
        libsnappy-dev \
        libhdf5-serial-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        liblmdb-dev \
        libclang-dev \
        libncurses5-dev \
        libbonoboui2-dev \
        libcairo2-dev \
        libgnome2-dev \
        libgnomeui-dev \
        libgtk2.0-dev \
        libx11-dev \
        libxpm-dev \
        libxt-dev \
        lsb-release \
        lua5.1 \
        lua5.1-dev \
        libperl-dev \
        python-dev \
        python-pip \
        protobuf-compiler \
        python-pip \
        python-matplotlib \
        python-sklearn \
        python-protobuf \
        python-leveldb \
        python-networkx \
        python-nose \
        python-pandas \
        python-gflags \
        python-opencv \
        python-software-properties \
        python3-dev \
        libhdf5-serial-dev \
        cmake \
        libatlas-base-dev \
        rake \
        ruby-dev \
        silversearcher-ag \
        software-properties-common \
        wget \
        tmux

RUN pip install --upgrade -r requirements.txt

# install g++/gcc 5
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y gcc-5 g++-5 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 \
        60 --slave /usr/bin/g++ g++ /usr/bin/g++-5

# config the tmux for all users by default
RUN cp /app/.tmux.conf /etc/skel/

# remove the older vim and we will install a newer one
RUN apt-get remove -y vim vim-runtime gvim

# install the latest vim to support the YCM
RUN git clone https://github.com/vim/vim.git && \
    cd vim/src && \
    ./configure --with-features=huge \
                --enable-multibyte \
                --enable-rubyinterp \
                --enable-pythoninterp \
                --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
                --enable-python3interp \
                --enable-perlinterp \
                --enable-luainterp \
                --enable-gui=gtk2 --enable-cscope --prefix=/usr && \
    make VIMRUNTIMEDIR=/usr/share/vim/vim80 && \
    make install && \
    update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1 && \
    update-alternatives --set editor /usr/bin/vim && \
    update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1 && \
    update-alternatives --set vi /usr/bin/vim && \
    cd ../../

# clone the Vundle into a global position for all users
RUN git clone https://github.com/VundleVim/Vundle.vim.git /etc/vim/bundle/Vundle.vim

RUN python generate_vimrc.py

RUN cp /app/.vimrc_plugin_global $HOME/.vimrc && \
    vim +PluginInstall +qall

# install ycm
ENV CLANG_FILE_NAME clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-14.04
ENV CLANG_TAR_FILE_NAME ${CLANG_FILE_NAME}.tar.xz
RUN rm -f $CLANG_TAR_FILE_NAME && \
	wget http://releases.llvm.org/4.0.0/${CLANG_TAR_FILE_NAME} && \
	tar xf $CLANG_TAR_FILE_NAME && \
	rm -rf ycm_build && \
	mkdir ycm_build && \
	cd ycm_build && \
	cmake -G "Unix Makefiles" \
		-DPATH_TO_LLVM_ROOT=../${CLANG_FILE_NAME} . \
		/etc/vim/bundle/Vundle.vim/YouCompleteMe/third_party/ycmd/cpp && \
	cmake --build . --target ycm_core --config Release && \
    rm -rf $CLANG_TAR_FILE_NAME

RUN git clone https://github.com/NVIDIA/nccl.git && \
        cd nccl && make -j install && \
        cd .. && rm -rf nccl

RUN cd /etc/vim/bundle/Vundle.vim/command-t && \
    rake make

RUN cp /app/.vimrc_global /etc/skel/.vimrc

RUN rm /app/* -rf
RUN rm /root/* -rf

CMD ["sleep", "infinity"]
