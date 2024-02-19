

sudo rm -rf  ~/mnt/tmpd && mkdir ~/mnt/tmpd

export TMPDIR=/users/shoaibCS/mnt/tmpd
set -euo pipefail


set +u
source "$($CONDA_EXE info --base)/etc/profile.d/conda.sh"
set -u

# stage -1: install dependencies

#conda env create --force -v --file environment.yml

set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
#conda activate mlperf
set -u
echo "1"

#conda create -n llm python=3.9 -y
conda activate llm

if [ "$1" -eq 1 ]; then

echo "11111"

conda install mkl mkl-include -y
conda install gperftools jemalloc==5.2.1 -c conda-forge -y

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
conda install pyarrow
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

echo "3"

# Setup Environment Variables
export KMP_BLOCKTIME=1
export KMP_SETTINGS=1
export KMP_AFFINITY=granularity=fine,compact,1,0
# IOMP
LD_PRELOAD="/users/shoaibCS/mnt/scripts"
export LD_PRELOAD=${LD_PRELOAD}:${CONDA_PREFIX}/lib/libiomp5.so
# Tcmalloc is a recommended malloc implementation that emphasizes fragmentation avoidance and scalable concurrency support.
export LD_PRELOAD=${LD_PRELOAD}:${CONDA_PREFIX}/lib/libtcmalloc.so

echo "4"
pip3 install pybind11
cd ../loadgen
CFLAGS="-std=c++14 -O3" python setup.py bdist_wheel
cd ..; pip3 install --force-reinstall loadgen/dist/mlperf_loadgen-4.0-cp312-cp312-linux_x86_64.whl

#cd ..; pip3 install --force-reinstall loadgen/dist/`ls -r loadgen/dist/ | head -n1` ; cd -
cd loadgen
cp ../mlperf.conf ../../
cd ../..
echo "5"
cd ../language/gpt-j
python download_cnndm.py

echo "6"
pip3 install datasets
python prepare-calibration.py --calibration-list-file calibration-list.txt --output-dir ../language/gpt-j/output
echo "7"

mkdir -p model/

wget https://cloud.mlcommons.org/index.php/s/QAZ2oM94MkFtbQx/download --output-document checkpoint.zip
unzip checkpoint.zip -d model/

echo "8"
elif [ "$1" -eq 2 ]; then

cp ../data/cnn_eval.json ../inference/language/gpt-j/data/
cd ../language/gpt-j/
python main.py --scenario=Offline --model-path=./model/gpt-j/checkpoint-final/ --dataset-path=./data/cnn_eval.json --max_examples=1

else 
	echo "Invalid argument. Please use 1 to install dependencies or 2 to execute the final command."
fi

echo "9"
#python run.py --backend pytorch \
 #              --dataset_dir $local_data_dir \
  #             --manifest $local_data_dir/dev-clean-wav.json \
   #            --pytorch_config_toml pytorch/configs/rnnt.toml \
    #           --pytorch_checkpoint $work_dir/rnnt.pt \
     #          --scenario ${scenario} \
      #         --backend ${backend} \
       #        --log_dir ${log_dir} \
        #       ${accuracy} 
