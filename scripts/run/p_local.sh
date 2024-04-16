#!/bin/bash
#
# Run Caspian CXL-memory experiments: SPEC CPU 2017
#

PERF="/usr/bin/perf"
EMON="/opt/intel/oneapi/vtune/2021.1.2/bin64/emon"
RUNDIR="/home/shoaib/runc_2"

# Output folder
#RSTDIR="rst/emon-$(date +%F-%H%M)-$(uname -n | awk -F. '{printf("%s.%s\n", $1, $2)}')"
MEMEATER="$RUNDIR/memeater"
CPU2017_RUN_DIR="${RUNDIR}/cpu2017"
#RSTDIR="${CPU2017_RUN_DIR}/rst/emon-one"
RSTDIR="${CPU2017_RUN_DIR}/rst/asplos22"

RUN_EMON=0 # 1

# Reserve newlines during command substitution
#IFS=

if [[ $# != 1 && $# != 2 ]]; then
    echo ""
    echo "$0 wi.txt"
    echo "$0 w.txt 1"
    echo ""
    exit
fi

WF=$1
WID=$2

if [[ $# == 1 ]]; then
    warr=($(cat $WF | awk '{print $1}'))
    marr=($(cat $WF | awk '{print $2}'))
elif [[ $# == 2 ]]; then
    warr=($(cat $WF | awk -vline=$WID 'NR == line {print $1}'))
    marr=($(cat $WF | awk -vline=$WID 'NR == line {print $2}'))
fi
#warr=($(cat w8t.txt))
#echo ${warr[@]}
#echo ${marr[@]}

echo "==> Result directory: $RSTDIR"
# Suppose the host server has 2 nodes, [Node 1: 8c/32g + Node 2: 8c/32g]

# (1).
# Emulated CXL-memory cases
# (N1:8c/32g + N2:0c/32g)
# "100" -> 100% local memory configuration
# "50"  -> 50% local memory
# "0"   -> 0% local memory

# (2).
# NUMA baseline cases
# (N1:8c/32g + N2:8c/32g)
# "Interleave" -> round robin memory allocation across NUMA nodes

# Source global functions
source $RUNDIR/cxl-global.sh || exit

#[[ -e $EMON ]] || exit

echo "Checking perf ..."
[[ -e $PERF ]] || exit
echo "Finished checking"

TIME_FORMAT="\n\n\nReal: %e %E\nUser: %U\nSys: %S\nCmdline: %C\nAvg-total-Mem-kb: %K\nMax-RSS-kb: %M\nSys-pgsize-kb: %Z\nNr-voluntary-context-switches: %w\nCmd-exit-status: %x"

if [[ ! -e /usr/bin/time ]]; then
    echo "Please install GNU time first!"
    exit
fi

# Must be called under the corresponding workload folder (e.g. 519.lbm_r/)
# $1: workload
# $2: exp type (L100, L50, L0, "CXL-Interleave")
# $3: exp ID
# $4: workload wss, required for running more splits (L95 -- L75)
# Require taking all CPUs on Node 1 offline
run_one_exp()
{
    local w=$1
    local et=$2
    local id=$3
    local mem=$4
    #local run_cmd="$(cat cmd.sh | grep -v "^#")"
    local run_cmd="bash cmd.sh" # the command line string
    local MEM_SHOULD_RESERVE=0
    flush_fs_caches

    echo "    => Running [$w - $et - $id], date:$(date) ..."

    if [[ $et == "L100" ]]; then
        run_cmd="numactl --cpunodebind 0 --membind 0 -- ""${run_cmd}"
    elif [[ $et == "L0" ]]; then
        run_cmd="numactl --cpunodebind 0 --membind 1 -- ""${run_cmd}"
    elif [[ $et == "CXL-Interleave" ]]; then
        run_cmd="numactl --cpunodebind 0 --interleave=all -- ""${run_cmd}"
    elif [[ $et == "Base-Interleave" ]]; then
        # The difference with L50 is that all CPUs on Node 1 are online
        # --cpunodebind 0: this param was errorneously added, need to fix for
        # those multi-threaded workloads!!!! (re-run workloads >600)
        run_cmd="numactl --interleave=all -- ""${run_cmd}"
    else
        # Other base splits (e.g. 90, 80, 70, 60)
        run_cmd="numactl --cpunodebind 0 -- ${run_cmd}"
        #NODE0_TT_MEM=$(sudo numactl --hardware | grep 'node 0 size' | awk '{print $4}')
        NODE0_FREE_MEM=$(sudo numactl --hardware | grep 'node 0 free' | awk '{print $4}')
        ((NODE0_FREE_MEM -= 520))
        # 549 -> 873MB
        APP_MEM_ON_NODE0=$(echo "$mem*$et/100.0" | bc)
        #echo $NODE0_FREE_MEM
        MEM_SHOULD_RESERVE=$((NODE0_FREE_MEM - APP_MEM_ON_NODE0))
        MEM_SHOULD_RESERVE=${MEM_SHOULD_RESERVE%.*}
        #echo $MEM_SHOULD_RESERVE
        #return
    fi

    local output_dir="$RSTDIR/$w/CXL"
    [[ ! -d ${output_dir} ]] && mkdir -p ${output_dir}

    local logf=${output_dir}/${et}-${id}.log
    local timef=${output_dir}/${et}-${id}.time
    local output=${output_dir}/${et}-${id}.output
    local memf=${output_dir}/${et}-${id}.mem
    local pidstatf=${output_dir}/${et}-${id}.pidstat
    local sysinfof=${output_dir}/${et}-${id}.sysinfo
    local emondatf=${output_dir}/${et}-${id}-emon.dat
    local sarf=${output_dir}/${et}-${id}.sar
    local proccf=${output_dir}/${et}-${id}.procc
    local freqf=${output_dir}/${et}-${id}.freq
    local iof=${output_dir}/${et}-${id}.io

    local perfoutput=${output_dir}/${et}-${id}.data
    local state=${output_dir}/${et}-${id}.state

    {
        echo "===> MemEater reserving [$MEM_SHOULD_RESERVE] MB on Node 0..."
        if [[ $MEM_SHOULD_RESERVE -gt 0 ]]; then
            sudo killall memeater >/dev/null 2>&1
            sleep 10
            # Make sure that MemEater is reserving memory from Node 0
            numactl --cpunodebind 0 --membind 0 -- $MEMEATER ${MEM_SHOULD_RESERVE} &
            mapid=$!
            # Wait until memory eater consume all destined memory
            sleep 120
        fi

	local perf_events="instructions,cycles"
        perf_events="${perf_events}"",MEM_INST_RETIRED.ALL_LOADS,MEM_INST_RETIRED.ALL_STORES"
	perf_events="${perf_events}"",MEM_LOAD_RETIRED.L1_HIT,MEM_LOAD_RETIRED.L1_MISS,MEM_LOAD_RETIRED.FB_HIT"
	perf_events="${perf_events}"",EXE_ACTIVITY.BOUND_ON_STORES,CYCLE_ACTIVITY.STALLS_TOTAL"
	perf_events="${perf_events}"",CYCLE_ACTIVITY.STALLS_L1D_MISS,CYCLE_ACTIVITY.STALLS_L2_MISS,CYCLE_ACTIVITY.STALLS_L3_MISS"
#	perf_events="${perf_events}"",MEM_LOAD_RETIRED.L2_MISS,MEM_LOAD_RETIRED.L3_MISS"
#	perf_events="${perf_events}"",MEM_LOAD_RETIRED.L2_HIT,MEM_LOAD_RETIRED.L3_HIT"
#	perf_events="${perf_events}"",cpu/L1D_PEND_MISS.FB_FULL,cmask=1/,L1D_PEND_MISS.FB_FULL"
#	perf_events="${perf_events}"",L2_RQSTS.ALL_PF,L2_RQSTS.PF_HIT,L2_RQSTS.PF_MISS"
#	perf_events="${perf_events}"",OFFCORE_RESPONSE.PF_L1D_AND_SW.ANY_RESPONSE,OFFCORE_RESPONSE.PF_L1D_AND_SW.L3_HIT.ANY_SNOOP"
#	perf_events="${perf_events}"",OFFCORE_RESPONSE.PF_L2_DATA_RD.ANY_RESPONSE,OFFCORE_RESPONSE.PF_L2_DATA_RD.L3_HIT.ANY_SNOOP"
#	perf_events="${perf_events}"",LONGEST_LAT_CACHE.MISS"
	#perf_events="${perf_events}"",LONGEST_LAT_CACHE.MISS,LONGEST_LAT_CACHE.REFERENCE"

	# Counts all prefetch data reads that miss in the L3.
	#perf_events="${perf_events}"",OFFCORE_RESPONSE.ALL_PF_DATA_RD.L3_MISS.ANY_SNOOP"
	#perf_events="${perf_events}"",OFFCORE_RESPONSE.ALL_PF_DATA_RD.L3_MISS.SNOOP_MISS_OR_NO_FWD"

	#perf_metrics="tma_info_dram_bw_use"
	perf_metrics=""
	#perf_metrics="${perf_metrics}""tma_memory_bound,tma_l1_bound,tma_l2_bound,tma_l3_bound,tma_dram_bound"

	run_cmd="$PERF stat -e ${perf_events} -o $perfoutput  ""${run_cmd}"


        echo "$run_cmd" | tee r.sh
        echo "Start: $(date)"
        get_sysinfo > $sysinfof 2>&1
	/home/shoaib/runc_2/mlcc --latency_matrix &>> $state
	/home/shoaib/runc_2/mlcc --bandwidth_matrix &>> $state
        /usr/bin/time -f "${TIME_FORMAT}" --append -o ${timef} bash r.sh > $output 2>&1 &
        #/usr/bin/time -f "${TIME_FORMAT}" --append -o ${timef} sleep 15 > $output 2>&1 &
        cpid=$!

#	mpstat -P 10,12,14,16,18 1 > $proccf &
	mpstat -P 0 1 > $proccf &
#	mpstat -P 10 1 > $proccf &

	proccfid=$!

        #pidstat -r -u -d -l -v -p ALL -U -h 5 1000000 > $pidstatf &
        #pstatpid=$!

        if [[ "${RUN_EMON}" == 1 ]]; then
            sudo $EMON -i $RUNDIR/clx-2s-events.txt -f "$emondatf" >/dev/null 2>&1 &
        fi
        #sar -o ${sarf} -bBdHqSwW -I SUM -n DEV -r ALL -u ALL 1 >/dev/null 2>&1 &
        #sarpid=$!
        monitor_resource_util >>$memf 2>&1 &
        mpid=$!
#	echo monitor_freq
	monitor_freq >>$freqf 2>&1 &
	freqid=$!
	monitor_io >>$iof 2>&1 &
	ioid=$!

        #disown $pstatpid
        #disown $sarpid
        disown $mpid # avoid the "killed" message
        wait $cpid 2>/dev/null
        if [[ "${RUN_EMON}" == 1 ]]; then
            sudo $EMON -stop
        fi
        #kill -9 $sarpid
	kill -9 $proccfid
	kill -9 $freqid
	kill -9 $ioid
        kill -9 $mpid >/dev/null 2>&1
        #kill -9 $pstatpid >/dev/null 2>&1
        if [[ $MEM_SHOULD_RESERVE -gt 0 ]]; then
            disown $mapid
            kill -9 $mapid >/dev/null 2>&1
        fi
        echo "End: $(date)"
        echo "" && echo "" && echo "" && echo ""
        cat r.sh
        echo ""
        cat cmd.sh
        rm -rf r.sh
        sleep 10
    } >> $logf
}

# run "L100" "CXL-Interleave" "L0" in one shot
# $1: "workload"
# $2: id
# $3: Memory (MB)
run_one_workload_cxl_L100()
{
    local w=$1
    local id=$2
    local mem=$3
    run_one_exp "$w" "L100" $id $mem
    return
}

run_one_workload_cxl_L0()
{
	local w=$1
	local id=$2
	local mem=$3
	run_one_exp "$w" "L0" $id $mem
	return	
}

# run baseline experiments (e.g. "Base-Interleave"), we put this into a seperate
# function as it does not require any hacks to take cores offline
# $1: "workload"
# $2: id
run_one_workload_base()
{
    local w=$1
    local id=$2

    run_one_exp "$w" "Base-Interleave" $id
}

# Run all 43 SPEC CPU workloads on one server one by one Params:
# $1 -> the experiment type to run.
#
# "L100", "L50", "L0" -> represent the CXL-based exp
# "B50" -> Baseline interleave mode, "L100" <=> "B100"
run_seq_cxl_L0_1()
{
    #check_base_conf
    #reset_base
    check_cxl_conf
    for id in 1; do
        for ((i = 0; i < ${#warr[@]}; i++)); do
            w=${warr[$i]}
            m=${marr[$i]}
            cd "$w"
            run_one_workload_cxl_L0 "$w" "$id" "$m"
            cd ../
        done
    done
}

run_seq_cxl_L0_2()
{
	#check_base_conf
	#reset_base
	check_cxl_conf
	for id in 2; do
		for ((i = 0; i < ${#warr[@]}; i++)); do
			w=${warr[$i]}
			m=${marr[$i]}
			cd "$w"
			run_one_workload_cxl_L0 "$w" "$id" "$m"
			cd ../
		done
	done
}

run_seq_cxl_L100()
{
	#check_base_conf
	#reset_base
	check_cxl_conf
	for id in 100; do
		for ((i = 0; i < ${#warr[@]}; i++)); do
			w=${warr[$i]}
			m=${marr[$i]}
			cd "$w"
			run_one_workload_cxl_L100 "$w" "$id" "$m"
			cd ../
		done
	done
}

#./modify-uncore-freq.sh 2000000 2000000 2000000 2000000
#./modify-uncore-freq.sh 2000000 2000000 200000 200000
#./modify-uncore-freq.sh 2000000 2000000 100000 100000
#exit
#./modify-uncore-freq.sh 100000 100000 100000 100000
# 4 and 5 above
#6 below
#./modify-uncore-freq.sh 2000000 2000000 2000000 2000000
#7
./modify-uncore-freq.sh 100000 100000 2000000 2000000

#echo "2GHZ perf" >>log
#./mlcc --latency_matrix >>log
#./mlcc --bandwidth_matrix >>log
echo "Run L100"
run_seq_cxl_L100
echo "Run L0 1"
run_seq_cxl_L0_1
#./modify-uncore-freq.sh 2000000 2000000 500000 500000
#echo "Run L0 2"
#run_seq_cxl_L0_2
echo "./run-perf_m.sh FINISHED"

exit
exit
exit

#ssh -n -f h0.speccpu2017.memdisagg "sh -c 'cd ~/proj/run; nohup { time ./r.sh ; } 2>L0.time >/dev/null 2>&1 &'"
