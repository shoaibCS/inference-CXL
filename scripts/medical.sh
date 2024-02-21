
#/bin/bash
#export work_dir=""
#export stage="-1"
if [ "$1" -eq 1 ]; then

set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate llm
set -u
whereis python

conda install nibabel -y
conda install scipy -y

cd ../vision/medical_imaging/3d-unet-kits19/
make setup

#need python 3.8 make preprocess_data

cp ../data/inference_cases.json ../vision/medical_imaging/3d-unet-kits19/meta

rm -rf build/raw_data && mv kits19_raw_data_dir/kits19/data/ build/raw_data

cp ../../../data/inference_cases.json meta/
cp ../../../data/medical_mlperf.conf  build/mlperf.conf
make preprocess_data
#whereis python
#cp ../data/medical_mlperf.conf ../vision/medical_imaging/3d-unet-kits19/build/mlperf.conf

elif [ "$1" -eq 2 ]; then

set +u
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate llm
set -u


cd ../vision/medical_imaging/3d-unet-kits19 && $CONDA_PREFIX/bin/python run.py --backend=pytorch --scenario=Offline


else
	echo "wrong args"
fi

