sed -i .tmp '/=/!d' ./params.txt
rm ./params.txt.tmp
source ./params.txt
mv ./params.txt $outdir
cd $outdir

# creating log file
logfile=$outdir/SeqExtract.log-`date +%H.%M.%S`.txt
touch $logfile
echo "Start: `date`" >> $logfile
echo "Database folder: $refs_path" >> $logfile
echo "Query type recorded as $query_type.
Target type recorded as $database_type." >> $logfile

# making db directory
db_dir=$outdir/db
mkdir $db_dir && cd $db_dir

# making a combined reference fasta file
cat $refs_path/*.fa > $db_dir/combinedrefs.fasta

# checking makeblastdb version
makeblastdb_version=`makeblastdb -version | sed -n '1 p'`
echo "BLAST database construction using $makeblastdb_version" >> $logfile

# running makeblastdb
makeblastdb -in $db_dir/combinedrefs.fasta -dbtype $database_type

# updating log
echo "CHECKPOINT 1
BLAST database construction completed." >> $logfile

# running appropriate blast
$blast_type -db $db_dir/combinedrefs.fasta -evalue 1e-20 -outfmt 6 -max_target_seqs $num_refs -query $query_path -out $outdir/SeqExt.$blast_type.hits.outfmt6

echo "CHECKPOINT 2
BLAST search using `$blast_type -version | sed -n '1 p'` completed" >> $logfile

## splitting results into separate files
sep_res_dir=$outdir/separated_results
mkdir $sep_res_dir
awk -F"\t" 'BEGIN {OFS = FS} {print>t"/"$1".txt"}' t=$sep_res_dir $outdir/SeqExt.*

## get coordinates for sequence extraction
coord_dir=$outdir/coords
mkdir $coord_dir

for res_file in $sep_res_dir/*.txt
    do
        base=`basename $res_file .txt`
        awk -F"\t" 'BEGIN {OFS=FS} {if ($9<$10) print $2":"$9"-"$10}' $res_file > $coord_dir/$base.coords_forward.txt
        awk -F"\t" 'BEGIN {OFS=FS} {if ($9>$10) print $2":"$10"-"$9}' $res_file > $coord_dir/$base.coords_reverse.txt
        samtools faidx $db_dir/combinedrefs.fasta -c -r $coord_dir/$base.coords_forward.txt --mark-strand sign > $outdir/$base.sequences.forward.txt
        samtools faidx $db_dir/combinedrefs.fasta -c -r $coord_dir/$base.coords_reverse.txt --reverse-complement --mark-strand sign > $outdir/$base.sequences.reverse.txt
        cat $outdir/$base.sequences.forward.txt $outdir/$base.sequences.reverse.txt > $outdir/$base.sequences.txt
        rm $outdir/$base.sequences.forward.txt
        rm $outdir/$base.sequences.reverse.txt
    done

echo "BLAST results in tabular format in $outdir/SeqExt.$blast_type.hits.outfmt6
BLAST results split by query sequence stored in $sep_res_dir
Coordinates used to extract hits from targets stored in $coord_dir
Sequence hits extratced from targets stored in $outdir with the suffix .sequences.txt
" >> $logfile

echo "Done, hopefully!" >> $logfile
