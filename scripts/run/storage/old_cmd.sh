taskset -c 10 fio --name=sequential_read_test --ioengine=io_uring --rw=write --bs=1M --direct=1 --filename=/data/cxl/cxl-storage_200.file --size=200G --numjobs=1 --iodepth=1024
