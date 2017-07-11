#!/bin/bash
#PBS -N redkmer8
#PBS -l walltime=72:00:00
#PBS -l select=1:ncpus=24:mem=16gb:tmpspace=5gb
#PBS -e /work/nikiwind/
#PBS -o /work/nikiwind/

source $PBS_O_WORKDIR/redkmer.cfg

for BINNAME in Abin Ybin GAbin;
do

if [ -s "$CWD/pacBio_bins/fasta/${BINNAME}.fasta" ];then
	echo "Bin found: ${BINNAME}"
else
	echo "Bin not found: ${BINNAME}"
	touch $CWD/kmers/bowtie/offtargets/kmer_hits_${BINNAME}
	continue
fi

NREADS=$(cat $CWD/pacBio_bins/fasta/${BINNAME}splitter | echo $((`wc -l`)))
if [ "$NREADS" -le 110000 ];
then
	NODES=2
else
	NODES=$(((${NREADS}/100000)+5))
fi

cat > ${CWD}/qsubscripts/off_${BINNAME}.bashX <<EOF
#!/bin/bash
#PBS -N redk_o_${BINNAME}${i}
#PBS -l walltime=12:00:00
#PBS -l select=1:ncpus=12:mem=64gb:tmpspace=500gb
#PBS -e ${CWD}/reports
#PBS -o ${CWD}/reports
#PBS -J 1-${NODES}
module load bowtie/1.1.1
module load intel-suite

	echo "==================================== Indexing offtarget ${BINNAME}, chunk ${PBS_ARRAY_INDEX}  ======================================="
			#cp $CWD/pacBio_bins/fasta/${PBS_ARRAY_INDEX}_${BINNAME}.fasta XXXXXTMPDIR
			#$BOWTIEB -o 3 --large-index XXXXXTMPDIR/${PBS_ARRAY_INDEX}_${BINNAME}.fasta XXXXXTMPDIR/${PBS_ARRAY_INDEX}_${BINNAME}
			#cp XXXXXTMPDIR/${PBS_ARRAY_INDEX}_${BINNAME}* $CWD/kmers/bowtie/index/
		cp $CWD/kmers/bowtie/index/${PBS_ARRAY_INDEX}_${BINNAME}* XXXXXTMPDIR 
	echo "==================================== Aligning ${BINNAME}, chunk ${PBS_ARRAY_INDEX} ======================================="
		cp $CWD/kmers/fasta/Xkmers.fasta XXXXXTMPDIR
		$BOWTIE -a -t -p $CORES --large-index -v 2 XXXXXTMPDIR/${PBS_ARRAY_INDEX}_${BINNAME} --suppress 2,3,4,5,6,7,8,9 -f XXXXXTMPDIR/Xkmers.fasta  1> XXXXXTMPDIR/${BINNAME}.txt 2> $CWD/kmers/bowtie/offtargets/logs/${PBS_ARRAY_INDEX}_${BINNAME}_log.txt
	echo "==================================== Counting ${BINNAME}, chunk ${PBS_ARRAY_INDEX} ===================================="

		cp ${BASEDIR}/Cscripts/* XXXXXTMPDIR
		make
		./count XXXXXTMPDIR/${BINNAME}.txt > XXXXXTMPDIR/${BINNAME}.counted
		awk '{print XXXXX2, XXXXX1}' XXXXXTMPDIR/${BINNAME}.counted > $CWD/kmers/bowtie/offtargets/${PBS_ARRAY_INDEX}_kmer_hits_${BINNAME}
		
	echo "==================================== Done ${BINNAME}, chunk ${PBS_ARRAY_INDEX} ===================================="
EOF
sed 's/XXXXX/$/g' ${CWD}/qsubscripts/off_${BINNAME}.bashX > ${CWD}/qsubscripts/off_${BINNAME}.bash

qsub ${CWD}/qsubscripts/off_${BINNAME}.bash

done

printf "======= done step 8 =======\n"
