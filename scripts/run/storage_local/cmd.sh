taskset -c 0 fio conf.fio
#taskset -c 0,2 fio conf.fio

#taskset -c 8,10,12,14,24 fio conf.fio

#cd /home/shoaib/runc_2/filebench && filebench -f my_works/new.f

#taskset -c 10,12,14,16,18 fio conf.fio

#taskset -c 10 fio --name=sequential_read_test --ioengine=io_uring --rw=write --bs=1M --direct=1 --filename=/data/cxl/cxl-storage_200.file --size=200G --numjobs=1 --iodepth=1024
