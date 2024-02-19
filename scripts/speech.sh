
#/bin/bash
#export work_dir=""
#export stage="-1"
if [ "$1" -eq 1 ]; then

sudo rm -rf ./tmpd && mkdir ./tmpd
export TMPDIR=/users/shoaibCS/mnt/tmpd
set -euo pipefail


work_dir=../speech_recognition/rnnt/speech
local_data_dir=$work_dir/local_data
librispeech_download_dir=$local_data_dir/LibriSpeech
sudo rm -rf $work_dir
stage=-1

mkdir -p $work_dir $local_data_dir $librispeech_download_dir

install_dir=third_party/install
mkdir -p $install_dir
install_dir=$(readlink -f $install_dir)

set +u
source "$($CONDA_EXE info --base)/etc/profile.d/conda.sh"
set -u

# stage -1: install dependencies

conda env create --force -v --file environment.yml

set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate ml
set -u

    # We need to convert .flac files to .wav files via sox. Not all sox installs have flac support, so we install from source.
wget https://ftp.osuosl.org/pub/xiph/releases/flac/flac-1.3.2.tar.xz -O third_party/flac-1.3.2.tar.xz
(cd third_party; tar xf flac-1.3.2.tar.xz; cd flac-1.3.2; ./configure --prefix=$install_dir && make && make install)

wget https://sourceforge.net/projects/sox/files/sox/14.4.2/sox-14.4.2.tar.gz -O third_party/sox-14.4.2.tar.gz
(cd third_party; tar zxf sox-14.4.2.tar.gz; cd sox-14.4.2; LDFLAGS="-L${install_dir}/lib" CFLAGS="-I${install_dir}/include" ./configure --prefix=$install_dir --with-flac && make && make install)
pip3 install pybind11

pwd

cd ../
echo "-----------"
abc=$(git rev-parse --show-toplevel)

echo "$abc"
(cd $(git rev-parse --show-toplevel)/loadgen; python setup.py install)

export PATH="$install_dir/bin/:$PATH"

set +u
conda activate ml
set -u

# stage 0: download model. Check checksum to skip?
pwd
echo "!!!!!!"
echo "------"
wget https://zenodo.org/record/3662521/files/DistributedDataParallel_1576581068.9962234-epoch-100.pt?download=1 -O speech_recognition/rnnt/speech/rnnt.pt

echo "abcccc"
pwd

# stage 1: download data. This will hae a non-zero exit code if the
# checksum is incorrect.
cd speech_recognition/rnnt

python pytorch/utils/download_librispeech.py pytorch/utils/librispeech-inference.csv speech/local_data/LibriSpeech -e speech/local_data



python pytorch/utils/convert_librispeech.py --input_dir speech/local_data/LibriSpeech/dev-clean --dest_dir speech/local_data/dev-clean-wav --output_json speech/local_data/dev-clean-wav.json

elif [ "$1" -eq 2 ]; then
cp ../data/set2/set_1.json ../speech_recognition/rnnt/speech/local_data/dev-clean-wav.json
cd ../speech_recognition/rnnt

conda activate ml

$CONDA_PREFIX/envs/ml/bin/python run.py --backend pytorch --dataset_dir ./speech/local_data --manifest ./speech/local_data/dev-clean-wav.json --pytorch_config_toml pytorch/configs/rnnt.toml --pytorch_checkpoint ./speech/rnnt.pt --scenario Offline --backend pytorch --log_dir log_dir=./speech/Offline_pytorchyyyy22

else
	echo "wrong args"
fi

