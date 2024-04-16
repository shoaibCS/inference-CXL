number_of_times=6
DIR1="/users/shoaibCS/mnt/inference/vision/medical_imaging/3d-unet-kits19/build/preprocessed_data_"

DIR2="/users/shoaibCS/mnt/inference/vision/medical_imaging/3d-unet-kits19/build/preprocessed_data"

DEST="/users/shoaibCS/mnt/runc/cpu2017/rst/asplos22/segment"
for (( i=1; i<=number_of_times; i++ ))
do
   echo "hey"
   TEMP="$DIR1""$i" # Use DIR1 here
   FIN="$DIR2"
   echo "$FIN"
   sudo rm -rf $FIN 
   cp -r $TEMP $FIN
   sudo bash run-pcm.sh segment.txt 
   DEST_NEW="/users/shoaibCS/mnt/runc/cpu2017/rst/asplos22/segment_""$i"
   sudo chmod 777 $DEST
   sudo mv $DEST $DEST_NEW
done

