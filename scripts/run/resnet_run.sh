number_of_times=5
export MODEL_DIR=/users/shoaibCS/mnt/inference/vision/classification_and_detection/resent_data/model
export DATA_DIR=/users/shoaibCS/mnt/inference/vision/classification_and_detection/resent_data/validation

DIR1="/users/shoaibCS/mnt/inference/vision/classification_and_detection/resent_data/val_"

DIR2="/users/shoaibCS/mnt/inference/vision/classification_and_detection/resent_data/validation"

DEST="/users/shoaibCS/mnt/runc/cpu2017/rst/asplos22/resnet"
for (( i=1; i<=number_of_times; i++ ))
do
   echo "hey"
   TEMP="$DIR1""$i" # Use DIR1 here
   FIN="$DIR2"
   echo "$FIN"
   sudo rm -rf $FIN 
   cp -r $TEMP $FIN
   sudo bash perf.sh resnet.txt 
   DEST_NEW="/users/shoaibCS/mnt/runc/cpu2017/rst/asplos22/resnet_""$i"
   sudo chmod 777 $DEST
   sudo mv $DEST $DEST_NEW
done

