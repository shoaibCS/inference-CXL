fio --name=sequential_read_test --ioengine=io_uring --rw=write --bs=4K --direct=1 --filename=/data/cxl/cxl-storage_lat.file --size=50G --numjobs=8 --iodepth=8
