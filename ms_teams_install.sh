#!/bin/sh

GCC="gcc_7_3_0_release"
BASE_DIR="ms_teams"
MS_TEAMS_VERSION="1.4.00.13653"

sudo yum -y remove teams

sudo yum -y install svn texinfo-tex flex zip

cd ~/Downloads/

mkdir $BASE_DIR
cd $BASE_DIR

svn co "svn://gcc.gnu.org/svn/gcc/tags/$GCC/"

cd $GCC

./contrib/download_prerequisites

./configure --disable-multilib --enable-languages=c,c++

sudo make -j 8

sudo make install

gcc --version

cd ..

wget "https://packages.microsoft.com/yumrepos/ms-teams/teams-$MS_TEAMS_VERSION-1.x86_64.rpm"

sudo yum -y install "./teams-$MS_TEAMS_VERSION-1.x86_64.rpm"

sudo yum update

teams



