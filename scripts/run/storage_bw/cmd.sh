taskset -c 10,12,14,16,18,20,22,24 fio --name=sequential_read_test --ioengine=io_uring --rw=read --bs=1M --direct=1 --filename=/data/cxl/cxl-storage_990.file --size=990G --numjobs=8 --iodepth=8
