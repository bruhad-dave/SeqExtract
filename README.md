# SeqExtract -- In Progress ! ! !
Given a set of query sequences in FASTA format, BLAST for matches and extract matched sequences from target database using samtools
Currently requires that the user download FASTA files of interest (reference genomes, etc) to their computer

## TODO
* Check that all issues are raised and resolved as expected
* Interface directly with web databases
  * for NCBI database, add option "-remote"; then clean up data
  * for others?

# Pseudocode: "SE_cli.sh"
count number of options at launch
  if number of options == 0:
    pick runtype - GUI
  else:
    pick runtype - CLI
    
if runtype == "GUI":
  launch SE_gui.py
else:
  check number of arguments
  if correct number:
    collect inputs
    check inputs for issues and attempt to resolve
    pass inputs to "params.txt"
  else:
    print help and quit
    
# Pseudocode: "SE_gui.py"
* import PySimpleGUI

generate form to collect user input
check inputs for issues
if issues:
  raise exceptions and attempt to resolve (with gui prompts)

pass inputs to "params.txt"

# Pseudocode: "SE_wrapper.sh"
* source params.txt
clean up params.txt and move it to designated output path
read in variables
perform BLAST search
split BLAST output by query ID
get match start and end, examine if reverse-complement needed
collect coordinates to extract from database
samtools index into database and extract targets, reverse complement if needed
merge sequences into .sequences.txt
  
