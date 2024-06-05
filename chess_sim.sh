#!/bin/bash

# Check if a file argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <pgn-file>"
    exit 1
fi

pgn_file=$1

# Check if the file exists
if [ ! -f "$pgn_file" ]; then
    echo "File does not exist: $pgn_file"
    exit 1
fi

# Extract metadata and moves from the PGN file
metadata=$(grep -E '^\[.*\]$' "$pgn_file")
moves=$(grep -v '^\[' "$pgn_file" | tr '\n' ' ')

# Display metadata
echo "Metadata from PGN file:"
echo "$metadata"
echo

# Convert PGN moves to UCI format using parse_moves.py
uci_moves=$(python3 parse_moves.py "$moves")
uci_moves_array=()

# parse the uci_moves string into an array splitting by spaces
read -r -a uci_moves_array <<< "$uci_moves"

# Initialize game state
move_index=0
total_moves=${#uci_moves_array[@]}
moves_history=()

# Function to display the chess board
char_to_index() {
    case $1 in
        a) echo 0 ;;
        b) echo 1 ;;
        c) echo 2 ;;
        d) echo 3 ;;
        e) echo 4 ;;
        f) echo 5 ;;
        g) echo 6 ;;
        h) echo 7 ;;
        *) echo -1 ;;
    esac
}

# Function to display the chess board
display_board() {
    # Initialize the board
    board=("r n b q k b n r "
           "p p p p p p p p "
           ". . . . . . . . "
           ". . . . . . . . "
           ". . . . . . . . "
           ". . . . . . . . "
           "P P P P P P P P "
           "R N B Q K B N R ")
    
    for ((i = 0; i < move_index; i++)); do
        move=${moves_history[$i]}
        from=${move:0:2}
        to=${move:2:2}
        promotion=""

        if [ ${#move} -eq 5 ]; then
            promotion=${move:4:1}
        fi

        from_row=$((8 - ${from:1:1}))
        from_col=$(char_to_index "${from:0:1}")
        to_row=$((8 - ${to:1:1}))
        to_col=$(char_to_index "${to:0:1}")

        if [[ $from_col -lt 0 || $to_col -lt 0 || $from_row -lt 0 || $to_row -lt 0 ]]; then
            echo "Invalid move: $move"
            continue
        fi

        piece=${board[$from_row]:$((from_col * 2)):1}
        
        # Handle promotion
        if [ -n "$promotion" ]; then
            if [[ $piece =~ [P] ]]; then
                case $promotion in
                    q) piece='Q' ;;
                    r) piece='R' ;;
                    b) piece='B' ;;
                    n) piece='N' ;;
                esac
            else
                case $promotion in
                    q) piece='q' ;;
                    r) piece='r' ;;
                    b) piece='b' ;;
                    n) piece='n' ;;
                esac
            fi
        fi
        
        board[$from_row]="${board[$from_row]:0:$((from_col * 2))}. ${board[$from_row]:$((from_col * 2 + 2))}"
        board[$to_row]="${board[$to_row]:0:$((to_col * 2))}$piece ${board[$to_row]:$((to_col * 2 + 2))}"
    done
    
    echo "Move $move_index/$total_moves"
    echo "  a b c d e f g h"
    for ((i = 0; i < 8; i++)); do
        echo "$((8 - i)) ${board[$i]}$((8 - i))"
    done
    echo "  a b c d e f g h"
}



# Function to handle user input
handle_input() {
    while true; do
        echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
        read key

        case $key in
            d)
                if [ $move_index -lt $total_moves ]; then
                    moves_history+=(${uci_moves_array[$move_index]})
                    ((move_index++))
                    display_board
                else
                    echo "No more moves available."
                fi
                ;;
            a)
                if [ $move_index -gt 0 ]; then
                    ((move_index--))
                    unset moves_history[$move_index]
                    display_board
                else
                    display_board
                fi
                ;;
            w)
                move_index=0
                moves_history=()
                display_board
                ;;
            s)
                move_index=$total_moves
                moves_history=(${uci_moves_array[@]})
                display_board
                ;;
            q)
                echo "Exiting."
                echo End of game.
                exit 0
                ;;
            *)
                echo "Invalid key pressed: $key"
                ;;
        esac
    done
}

# Initial display of the board
display_board

# Start handling user input
handle_input
