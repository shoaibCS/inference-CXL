echo "starting resnet "
date
sudo bash counters.sh resnet.txt 
echo "end and waiting 60 seconds"
date

sleep 60

echo "starting bert"

sudo bash counters.sh bert.txt
echo "end and waiting 60 seconds"
date

