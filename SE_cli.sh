#!/bin/bash
scripts=`pwd`

function pick_runtype {
    if [[ $num_params -eq 0 ]]; then
        echo "GUI"
    else
        echo "CLI"
    fi
}

function error_check_runtype {
    if [[ $runtype == "CLI" ]]; then
	    if [[ $num_params -lt 10 ]]; then
            echo "One or more parameters not specified. REQUIRED:
            [-o] - path to output dir
            [-r] - path to dir containing target/sample files
            [-i] - input query file (FASTA)
            [-q] - molecule type in query file (nucl/prot)
            [-t] - molecule type in target file(s) (nucl/prot)"
            exit
        fi
    fi
}


function exception_outpath_occupied {
    contents=`ls $1 | wc -l`
    if [[ $contents -gt 0 ]]
    then
        echo "Specified output directory is not empty. A new directory - SeqExtract_Output.`date +%H.%M` - will be created in $1"
        cd $1 && mkdir ./SeqExtract_Output.`date +%H.%M`
    else
        echo $1
    fi
}

function exception_no_target_fasta {
    num_fasta=`ls $1/*.{fa,fasta} 2> /dev/null | wc -l`
    if [[ $num_fasta -gt 0 ]]; then
        echo $1
    else
        read -p "The database/target folder you have selected does not seem to contain any fasta files. Please enter another path. " new_refs_path
        new_num_fasta=`ls $new_refs_path/*.{fa,fasta} 2> /dev/null | wc -l`
        if [[ $new_num_fasta -gt 0 ]]; then
            echo $new_refs_path
        else
            exception_no_target_fasta $new_refs_path
        fi
    fi
}

function exception_query_not_fasta {
    if [[ ( $query_path == *.fa ) || ( $query_path == *.fasta ) ]]; then
        echo $query_path
    else
        read -p "Specified query file does not seem to be a fasta file. Please pick again. " newpath
        if [[ ( $newpath == *.fa ) || ( $newpath == *.fasta ) ]]; then
        	echo $newpath
        else
        	exception_query_not_fasta $newpath
        fi
    fi
}

function check_valid_moltype {
    if [[ ( $1 == "nucl" ) || ( $1 == "prot" ) ]]; then
        echo $1
    else
        echo "Invalid molecule type for $2. Please pick either nucl or prot."
        read new_moltype
        if [[ ( $new_moltype == "nucl" ) || ( $new_moltype == "prot" ) ]]; then
            echo $new_moltype
        else
            check_valid_moltype $new_moltype $2
        fi
    fi
}

function pick_blast_type {
    if [[ ( $1 == "nucl" ) && ( $2 == "nucl" ) ]]; then
        echo blastn
    elif [[ ( $1 == "prot" ) && ( $2 == "prot" ) ]]; then
        echo blastp
    elif [[ ( $1 == "nucl" ) && ( $2 == "prot" ) ]]; then
        echo blastx
    elif [[ ( $1 == "prot" ) && ( $2 == "nucl" ) ]]; then
        echo tblastn
    fi
}

function count_targets {
    num_fasta=`ls $1/*.{fa,fasta} 2> /dev/null | wc -l`
    echo $num_fasta
}

## collect arguments
while getopts o:r:i:q:t: flag
    do
        case "${flag}" in
            o ) outpath=${OPTARG} ;;
            r ) refs_path=${OPTARG} ;;
            i ) query_path=${OPTARG} ;;
            q ) query_type=${OPTARG} ;;
            t ) database_type=${OPTARG} ;;
        esac
    done

num_params=$#
runtype=`pick_runtype $num_params`
error_check_runtype $runtype

case $runtype in
    "GUI")
        # launch GUI
        `which python3` $scripts/SE_gui.py > params.txt
        #source params.txt
        #mv ./params.txt $outdir
        # run main
        `which bash` $scripts/SeqExtract_main.sh
        ;;
    "CLI")
        # handle exceptions
        outdir=`exception_outpath_occupied $outpath`
        refs_path=`exception_no_target_fasta $refs_path`
        query_path=`exception_query_not_fasta $query_path`
        query_type=`check_valid_moltype $query_type`
        database_type=`check_valid_moltype $database_type`
        blast_type=`pick_blast_type $query_type $database_type`
        num_refs=`count_targets $refs_path`

        #cd $outdir

        #set variables
        echo "outdir=$outdir
        refs_path=$refs_path
        query_path=$query_path
        query_type=$query_type
        database_type=$database_type
        blast_type=$blast_type
        num_refs=$num_refs" > params.txt

        # run main
        `which bash` $scripts/SeqExtract_main.sh
        ;;
esac
