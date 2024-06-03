#!/bin/bash

# we first check if the number of args is 2
if [ $# -ne 2 ]; then
    # if not, we print so and exit
    echo "Usage: $0 <source_pgn_file> <destination_directory>"
    exit 1
fi

# we save the input args in vars
pgn_src_file=$1
pgn_des_dir=$2

# now we save the base name of the src file to use it later
pgn_base_name=$(basename "$pgn_src_file")

# we check if the src file acctually exists
if [ ! -f $pgn_src_file ]; then
    # if not, we print so and exit
    echo "Error: File '$pgn_src_file' does not exist."
    exit 1
fi

# we check if the des dir exists 
if [ ! -d $pgn_des_dir ]; then
    # if it does not then we create one we the required name
    mkdir -p $pgn_des_dir
    # we print an indication for the user about the creation of the dir
    echo "Created directory '$pgn_des_dir'."
fi

# we initialize the file counter for the file's names
file_counter=1

# we extract from the input file and split the required 'sections' into individual "game files"
grep -zoP '(?s)(?=\[Event ).+?(?=\[Event |\Z)' "$pgn_src_file" | while IFS= read -r -d '' section
do
  # we set the output file name with the des dir and the base name of the src file
  pgn_single_game="$pgn_des_dir/${pgn_base_name}_$file_counter.pgn"
  
  # we save the section to the new game file
  echo "$section" > "$pgn_single_game"
  
  # we print a msg for the user that the file was created
  echo "Saved game to $pgn_single_game"
  
  # we increase the file counter
  ((file_counter++))

done

# we print a msg for the user that all games have been split and saved
echo "All games have been split and saved to '${pgn_des_dir}'".
