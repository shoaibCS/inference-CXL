

#/bin/bash
#export work_dir=""
#export stage="-1"

sudo rm -rf ./tmpd && mkdir ./tmpd
export TMPDIR=/users/shoaibCS/mnt/tmpd

export MKL_INTERFACE_LAYER="LP64,GNU"
if [ "$1" -eq 1 ]; then

set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate ml
set -u
whereis python

conda install nibabel -y
conda install scipy -y

cd ../language/bert/

make setup

#need python 3.8 make preprocess_data
elif [ "$1" -eq 2 ]; then


#conda create -n bert python=3.9 -y

conda env create --force -v --file bert.yml

set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate berta
set -u

pip3 install --force-reinstall numpy
# install pytorch
# you can find other nightly version in https://download.pytorch.org/whl/nightly/


#pip3 install https://download.pytorch.org/whl/nightly/cpu-cxx11-abi/torch-2.0.0.dev20230228%2Bcpu.cxx11.abi-cp39-cp39-linux_x86_64.whl

#rust pyarrow

echo "2"
sudo apt-get install python3-pip -y
# installation
pip3 install setuptools_rust
sudo apt-get install build-essential -y
pip3 install Cython --user
conda install pyarrow -y
#pip3 install pyarrow>=6.0.0
#sudo apt-get install build-essential

pip3 install transformers datasets
pip3 install evaluate accelerate simplejson nltk rouge_score
#pip3 evaluate
#pip3 install setuptools_rust
#pip3 accelerate 
#pip3 simplejson 

#pip3 nltk 
#pip3 rouge_score

pip3 install pybind11
cd ../loadgen
CFLAGS="-std=c++14 -O3" python setup.py bdist_wheel


cd ..; pip3 install --force-reinstall loadgen/dist/`ls -r loadgen/dist/ | head -n1` ; cd -
ls
pwd
echo "-----------------------------------------------------------------------------------------------------"



cd ../scripts



set -u
cp ../data/bert_mlperf.conf ../language/bert/build/mlperf.conf

cd ../language/bert && $CONDA_PREFIX/bin/python3 run.py --backend=tf --scenario=Offline --max_examples=1


else
	echo "wrong args"
fi

