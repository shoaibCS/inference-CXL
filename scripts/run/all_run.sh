number_of_times=2
DIR1="/users/shoaibCS/mnt/inference/speech_recognition/rnnt/set2/set_"

DIR2="/users/shoaibCS/mnt/inference/speech_recognition/rnnt/speech/local_data"

DEST="/users/shoaibCS/mnt/runc/cpu2017/rst/asplos22/speech"
for (( i=1; i<=number_of_times; i++ ))
do
   echo "hey"
   TEMP="$DIR1""$i"".json" # Use DIR1 here
   FIN="$DIR2""/dev-clean-wav.json"
   echo "$FIN"
   rm $FIN 
   cp $TEMP $FIN
   sudo bash run-pcm.sh speech.txt 
   DEST_NEW="/users/shoaibCS/mnt/runc/cpu2017/rst/asplos22/speech_""$i"
   sudo chmod 777 $DEST
   sudo mv $DEST $DEST_NEW
done

