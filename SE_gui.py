import os
from pathlib import Path
import PySimpleGUI as sg
from datetime import datetime as dt

sg.theme("Reddit")

layout = [[sg.Text("Collecting SeqExtract inputs...", font=("Helvetica", 21))],
          [sg.Text("Select output folder", size = (21, 3), font=("Helvetica", 16), justification='left'), sg.InputText(size = (63, 14)), sg.FolderBrowse(font=("Helvetica", 12)),],
          [sg.Text("Select target folder", size = (21, 3), font=("Helvetica", 16), justification='left'), sg.InputText(size = (63, 14)), sg.FolderBrowse(font=("Helvetica", 12))],
          [sg.Text("Select a query file", size = (21, 3), font=("Helvetica", 16), justification='left'), sg.InputText(size = (63, 14)), sg.FileBrowse(font=("Helvetica", 12))],
          [sg.Text("Enter query type (nucl | prot)", size = (21, 3), font=("Helvetica", 16), justification='left'), sg.InputText(size = (21, 14))],
          [sg.Text("Enter target type (nucl | prot)", size = (21, 3), font=("Helvetica", 16), justification='left'), sg.InputText(size = (21, 14))],
          [sg.Button("Continue", font=("Helvetica", 14)), sg.Button("Quit", font=("Helvetica", 14))]]

window = sg.Window("SeqExtract", layout)

while True:
	event, values = window.read()
	if event == sg.WIN_CLOSED or event == "Quit":
		exit()
	elif event == "Continue":
		break

#print(values)

outpath_ = values[0]
targetpath_ = values[1]
queryfile_ = values[2]
q_type = values[3]
t_type = values[4]
window.close()
#print(outpath_, targetpath_, queryfile_, q_type, t_type)

## handle exceptions
def check_outpath_contents(folder):
	"""check if outpath is empty, if not, make a new folder with the naming scheme SeqExtract_Output.datetime(hhmm)
	Args:
		folder: the folder selected by the user to which SeqExtract outputs are written
	Returns:
		the folder itself if the folder is empty, otherwise creates a new one with a timestamp to avoid overwriting existing folders
	"""
	out_path = Path(folder)
	if len(os.listdir(out_path)) == 0:
		return out_path
	else:
		sg.popup_timed("The output path you have selected is not empty. A new directory with the nomenclature SeqExtract_Output.datetime(hhmm) will be created. This window will close automatically.", title="Heads up!", auto_close_duration=5)
		os.chdir(out_path)
		now = dt.now().strftime("%H%M")
		os.mkdir(f"SeqExtract_Output.{now}")
		return folder+f"/SeqExtract_Output.{now}"


def count_fasta(folder):
	"""Count fasta files in target folder
	Args:
		folder: the folder selected by the user to which SeqExtract outputs are written
	Returns:
		the number of fasta files in the folder; counts .fa and .fasta
	"""
	folder_path = Path(folder)
	num_fasta = 0
	for filename in os.listdir(folder):
		if filename.endswith(".fa") or filename.endswith(".fasta"):
			num_fasta += 1
	return num_fasta


def check_target_has_fasta(folder):
	"""Check that target folder contains one or more fasta files
	Args:
		folder: the folder selected by the user to which SeqExtract outputs are written
	Returns:
		the folder itself if it contains fasta files (.fa/.fasta), else keeps generating a popup prompt to select another folder
	"""
	if count_fasta(folder) > 0:
		return folder
	else:
		target_path = sg.popup_get_folder("The target folder you selected does not contain any fasta files. Please select a folder containing one or more fasta files.")
		return check_target_has_fasta(target_path)


def check_query_filetype(filepath):
	"""Check that query file is a fasta file
	Args:
		filepath: the absolute path of the query fasta file specified by the user
	Returns:
		filepath if file is a fasta file (.fa/.fasta/.fna/.faa), otherwise keeps generating a popup prompt to select a valid file
	"""
	query_file = Path(filepath)
	basename, file_extension = os.path.splitext(query_file)
	if file_extension in [".fa", ".fasta", "fna", ".faa"]:
		return query_file
	else:
		filepath = sg.popup_get_file("The query file you have selected does not appear to be a fasta file based on its file extension. Please select a fasta file.")
		return check_query_filetype(filepath)


def check_valid_moltypes(which_type, mol_type):
	"""Make sure that the query and target types are valid; either "nucl" or "prot"

	Args:
		which_type: "query"/"target"
		mol_type: the type input by the user
	Returns:
		mol_type if valid, otherwise keeps generating a popup prompt to enter a valid type
	"""
	valid_types = ["nucl", "prot"]
	if mol_type in valid_types:
		return mol_type
	else:
		mol_type = sg.popup_get_text(f"Please select a valid {which_type} type -- either nucl or prot.")
		return check_valid_moltypes(which_type, mol_type)


def pick_blast_type(query_type, target_type):
	"""Select the blast algorithm to use, based on the molecule types of the query and target
	Args:
		query_type: "nucl"/"prot"
		target_type: "nucl"/"prot"
	Returns:
		the blast algorithm that will be used:
  		blastn (nucl/nucl),
    	blastp (prot/prot),
     	blastx(q=nucl/t=prot), or
      	tblastn (q=prot/t=nucl)
	"""
	if query_type == "nucl":
		if target_type == "nucl":
			blast_type = "blastn"
		elif target_type == "prot":
			blast_type = "blastx"
	elif query_type == "prot":
		if target_type == "nucl":
			blast_type = "tblastn"
		elif target_type == "prot":
			blast_type = "blastp"
	return blast_type


## applying exception handling functions to user input and getting the variables that will be passed to SeqExtract.sh
param_out_path = check_outpath_contents(outpath_)
param_target_path = check_target_has_fasta(targetpath_)
param_query_file = check_query_filetype(queryfile_)
param_query_type = check_valid_moltypes("query", q_type)
param_target_type = check_valid_moltypes("target", t_type)
param_blast_type = pick_blast_type(param_query_type, param_target_type)
param_num_fasta_targets = count_fasta(param_target_path)

## changing to corrected outdir
#os.chdir(Path(param_out_path))

## printing corrected variables; stdout will be piped into SeqExtract.params.txt; that file will be used as source by SeqExtract.sh
print(f"outdir={param_out_path}")
print(f"refs_path={param_target_path}")
print(f"query_path={param_query_file}")
print(f"query_type={param_query_type}")
print(f"database_type={param_target_type}")
print(f"blast_type={param_blast_type}")
print(f"num_refs={param_num_fasta_targets}")






