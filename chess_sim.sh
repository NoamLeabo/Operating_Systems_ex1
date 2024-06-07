#!/bin/bash

# check if a file argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <pgn-file>"
    exit 1
fi

pgn_file=$1

# check if the file exists
if [ ! -f "$pgn_file" ]; then
    echo "File does not exist: $pgn_file"
    exit 1
fi

# extract metadata and moves from the PGN file
metadata=$(grep -E '^\[.*\]$' "$pgn_file")
moves=$(grep -v '^\[' "$pgn_file" | tr '\n' ' ')

# display the metadata
echo "Metadata from PGN file:"
echo "$metadata"
echo

# convert PGN moves to UCI format
uci_moves=$(python3 parse_moves.py "$moves")
uci_moves_array=()

# parse the uci_moves string into an array splitting by spaces
read -r -a uci_moves_array <<< "$uci_moves"

# initialize the state of the game
move_index=0
total_moves=${#uci_moves_array[@]}
moves_history=()

# a function to convert a character to an index
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

# a function to display the chess board
display_board() {
    # initialize the appearance of the board
    board=("r n b q k b n r "
           "p p p p p p p p "
           ". . . . . . . . "
           ". . . . . . . . "
           ". . . . . . . . "
           ". . . . . . . . "
           "P P P P P P P P "
           "R N B Q K B N R ")

    # loop through the moves history and update the board    
    for ((i = 0; i < move_index; i++)); do
        move=${moves_history[$i]}
        from=${move:0:2}
        to=${move:2:2}
        promotion=""

        # check if the move has a promotion
        if [ ${#move} -eq 5 ]; then
            promotion=${move:4:1}
        fi

        # convert the move to row and column indices
        from_row=$((8 - ${from:1:1}))
        from_col=$(char_to_index "${from:0:1}")
        to_row=$((8 - ${to:1:1}))
        to_col=$(char_to_index "${to:0:1}")

        # check if the move is valid and inside the board
        if [[ $from_col -lt 0 || $to_col -lt 0 || $from_row -lt 0 || $to_row -lt 0 ]]; then
            echo "Invalid move: $move"
            continue
        fi

        # get the piece from the board
        piece=${board[$from_row]:$((from_col * 2)):1}
        
        # case of promotion
        if [ -n "$promotion" ]; then
            if [[ $piece =~ [P] ]]; then
                # white pawn promotion
                case $promotion in
                    q) piece='Q' ;;
                    r) piece='R' ;;
                    b) piece='B' ;;
                    n) piece='N' ;;
                esac
            else
                # black pawn promotion
                case $promotion in
                    q) piece='q' ;;
                    r) piece='r' ;;
                    b) piece='b' ;;
                    n) piece='n' ;;
                esac
            fi
        fi

        # case of castling
        if [[ $piece == "K" || $piece == "k" ]]; then
            # we change only the half of the row in which the castling is happening
            if [[ $from == "e1" && $to == "g1" ]]; then
                # white kingside castling
                board[7]="${board[7]:0:8}. R K . "
                continue
            elif [[ $from == "e1" && $to == "c1" ]]; then
                # white queenside castling
                board[7]=". . K R . ${board[7]:10:16}"
                continue
            elif [[ $from == "e8" && $to == "g8" ]]; then
                # black kingside castling
                board[0]="${board[0]:0:8}. r k . "
                continue
            elif [[ $from == "e8" && $to == "c8" ]]; then
                # black queenside castling
                board[0]=". . k r . ${board[0]:10:16}"
                continue
            fi
        fi

        # case of en_passant
        if [[ $piece =~ [Pp] && $((from_col != to_col)) && ${board[$to_row]:$((to_col * 2)):1} == "." ]]; then
            if [[ $piece == "P" ]]; then
                en_passant_row=$((to_row + 1))
            else
                en_passant_row=$((to_row - 1))
            fi
            # remove the captured pawn
            board[$en_passant_row]="${board[$en_passant_row]:0:$((to_col * 2))}. ${board[$en_passant_row]:$((to_col * 2 + 2))}"
        fi
        
        # update the board with the new move
        board[$from_row]="${board[$from_row]:0:$((from_col * 2))}. ${board[$from_row]:$((from_col * 2 + 2))}"
        board[$to_row]="${board[$to_row]:0:$((to_col * 2))}$piece ${board[$to_row]:$((to_col * 2 + 2))}"
    done
    
    # display the entire board
    echo "Move $move_index/$total_moves"
    echo "  a b c d e f g h"
    for ((i = 0; i < 8; i++)); do
        echo "$((8 - i)) ${board[$i]}$((8 - i))"
    done
    echo "  a b c d e f g h"
}



# function that gets the user input
handle_input() {
    # script loop
    while true; do
        echo "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit:"
        read key

        # switch case for the user input
        case $key in
            d)
                # check if there are more moves available
                if [ $move_index -lt $total_moves ]; then
                    moves_history+=(${uci_moves_array[$move_index]})
                    ((move_index++))
                    display_board
                else
                    echo "No more moves available."
                fi
                ;;
            a)
                # check if there are moves to go back to
                if [ $move_index -gt 0 ]; then
                    ((move_index--))
                    unset moves_history[$move_index]
                    display_board
                else
                    display_board
                fi
                ;;
            w)
                # go to the start of the game
                move_index=0
                moves_history=()
                display_board
                ;;
            s)
                # go to the end of the game
                move_index=$total_moves
                moves_history=(${uci_moves_array[@]})
                display_board
                ;;
            q)
                # quit the game
                echo "Exiting."
                echo End of game.
                exit 0
                ;;
            *)
                # invalid key pressed
                echo "Invalid key pressed: $key"
                ;;
        esac
    done
}

# we initial the display of the board
display_board

# then we start getting input from the user
handle_input
