function linkedin
    clear

    set cols (tput cols)
    set pad_length (math --scale=0 "$cols * 0.37")
    set pad (string repeat -n $pad_length ' ')

    function prompt_line --inherit-variable pad
        printf '%s' $pad

        set_color --bold 7ee787
        printf 'Sulthan@Arch'

        set_color normal
        printf ':'

        set_color b8c0ff
        printf '~'

        set_color normal
        printf '$ '

        set_color --bold e6edf3
        printf '%s\n' "$argv"

        set_color normal
    end

    function output_line --inherit-variable pad
        printf '%s' $pad
        set_color e6edf3
        printf '%s\n' "$argv"
        set_color normal
    end

    echo
    echo
    echo

    prompt_line 'whoami'
    output_line 'Sulthan H. Andyno'
    output_line 'Information Technology Student'
    output_line 'Telkom University Jakarta'

    echo

    prompt_line 'cat focus.txt'
    output_line 'Artificial Intelligence • Software Development • Cybersecurity'

    echo

    prompt_line 'echo $TAGLINE'
    output_line '"IT student by day, turning ideas into code by night."'

    echo

    prompt_line 'status'
    output_line 'Open to collaboration and new opportunities.'

    echo
    echo

    # Menunggu satu tombol tanpa menampilkan tulisan "read>"
    read --silent --nchars 1 --prompt-str '' hold

    functions --erase prompt_line
    functions --erase output_line
end
