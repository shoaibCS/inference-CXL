

#/bin/bash
#export work_dir=""
#export stage="-1"

sudo rm -rf ./tmpd && mkdir ./tmpd
export TMPDIR=/users/shoaibCS/mnt/tmpd

export MKL_INTERFACE_LAYER="LP64,GNU"
if [ "$1" -eq 1 ]; then

conda create -n bert python=3.8 -y

set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bert
set -u
whereis python

pip3 install pybind11
conda install tensorflow -y
conda install numpy -y
conda install transformers -y

conda install opencv
conda install -n bert -c conda-forge pycocotools

cd ../loadgen
CFLAGS="-std=c++14 -O3" python setup.py bdist_wheel
pip3 install --force-reinstall dist/mlperf_loadgen-4.0-cp38-cp38-linux_x86_64.whl

whereis python


cd ../language/bert/

make setup

#need python 3.8 make preprocess_data
elif [ "$1" -eq 2 ]; then


#conda create -n bert python=3.9 -y


set +u
source /home/shoaib/conda/etc/profile.d/conda.sh
conda activate bert
set -u


cp ../data/bert_mlperf.conf ../language/bert/build/mlperf.conf

#cd ../language/bert && $CONDA_PREFIX/bin/python3 run.py --backend=tf --scenario=Offline --max_examples=20
#cd ../language/bert && /home/shoaib/conda/envs/bert/bin/python run.py --backend=tf --scenario=Offline

cd ../vision/classification_and_detection && bash run_local.sh tf resnet50 cpu --max-batchsize 64

else
	echo "wrong args"
fi

