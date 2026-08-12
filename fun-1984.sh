#!/usr/bin/env bash
#
# 1984.sh - monitor CPU / RAM / GPU / VRAM su una riga sola
#
# Uso come funzione (aggiungi a ~/.bashrc):
#     source /home/andrea/1984.sh
#     1984.sh              # refresh ogni 1s, q o Ctrl-C per uscire
#     1984.sh -d 0.5       # intervallo di refresh in secondi
#     1984.sh -n 3         # esegue solo N frame e termina
#
# Lo script resta eseguibile anche direttamente: ./1984.sh -d 0.5
#
# Nota: niente `set -u`/`exit` qui dentro — modificherebbero o chiuderebbero
# la shell che fa il source. Le funzioni ausiliarie sono prefissate _1984_ per
# non collidere con altri nomi nella shell.

# ─── campionamento CPU: indice 0 = aggregato, 1..NCPU = singoli core ───────────
_1984_sample_cpu() {
    local i=0 label a b c d e f g h
    while read -r label a b c d e f g h _; do
        [[ $label == cpu* ]] || break
        cur_total[i]=$(( a + b + c + d + e + f + g + h ))
        cur_idle[i]=$(( d + e ))                 # idle + iowait
        ((i++))
    done < /proc/stat
    NCPU=$(( i - 1 ))
}

_1984_cpu_pct() {                                # <idx> -> P_TOT in decimi di %
    local dt=$(( cur_total[$1] - prev_total[$1] )) di=$(( cur_idle[$1] - prev_idle[$1] ))
    if (( dt <= 0 )); then P_TOT=0; return; fi
    P_TOT=$(( (dt - di) * 1000 / dt ))
    (( P_TOT > 1000 )) && P_TOT=1000
    (( P_TOT < 0 ))    && P_TOT=0
    return 0
}

_1984_busy_cores() {                             # -> BUSY: core sopra la soglia
    local i
    BUSY=0
    for (( i = 1; i <= NCPU; i++ )); do
        _1984_cpu_pct "$i"
        (( P_TOT >= BUSY_THRESHOLD )) && ((BUSY++))
    done
    return 0
}

# le funzioni di formattazione scrivono in una variabile globale:
# niente $( ) e quindi nessun fork nel percorso di rendering.
_1984_col_for() {                                # -> COL
    if   (( $1 < 500 )); then COL=$GRN
    elif (( $1 < 800 )); then COL=$YEL
    else                      COL=$RED; fi
}

_1984_pct_str() { printf -v PCT '%3d.%d%%' $(( $1 / 10 )) $(( $1 % 10 )); }

# ─── memoria ───────────────────────────────────────────────────────────────────
_1984_read_mem() {
    local k v u
    MemTotal=1; MemFree=0; Buffers=0; Cached=0; SReclaimable=0; Shmem=0
    while read -r k v u; do
        case $k in
            MemTotal:|MemFree:|Buffers:|Cached:|SReclaimable:|Shmem:)
                printf -v "${k%:}" '%s' "$v" ;;
            Percpu:) break ;;
        esac
    done < /proc/meminfo
    CacheTot=$(( Cached + SReclaimable - Shmem ))
    (( CacheTot < 0 )) && CacheTot=0
    MemUsed=$(( MemTotal - MemFree - Buffers - CacheTot ))
    (( MemUsed < 0 )) && MemUsed=0
    return 0
}

# ─── GPU ───────────────────────────────────────────────────────────────────────
_1984_detect_gpu() {                             # una volta sola per shell
    [[ -n ${_1984_GPU_MODE:-} ]] && return 0
    _1984_GPU_MODE=none
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
        _1984_GPU_MODE=nvidia
    else
        local c
        for c in /sys/class/drm/card[0-9]/device/mem_info_vram_total; do
            [[ -r $c ]] && { _1984_GPU_MODE=amd; _1984_AMD_DEV=${c%/mem_info_vram_total}; break; }
        done
    fi
    return 0
}

_1984_read_gpu() {
    VRAM_USED=0; VRAM_TOTAL=0; GPU_UTIL=-1       # GPU_UTIL in decimi di percento
    case $_1984_GPU_MODE in
      nvidia)
        local line u t g
        line=$(nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu \
                          --format=csv,noheader,nounits 2>/dev/null | head -1)
        [[ -z $line ]] && return 1
        IFS=',' read -r u t g <<< "$line"
        VRAM_USED=$(( ${u// /} * 1024 ))         # MiB -> kB
        VRAM_TOTAL=$(( ${t// /} * 1024 ))
        g=${g// /}
        [[ $g =~ ^[0-9]+$ ]] && GPU_UTIL=$(( g * 10 ))
        ;;
      amd)
        VRAM_USED=$(( $(<"$_1984_AMD_DEV/mem_info_vram_used") / 1024 ))
        VRAM_TOTAL=$(( $(<"$_1984_AMD_DEV/mem_info_vram_total") / 1024 ))
        if [[ -r $_1984_AMD_DEV/gpu_busy_percent ]]; then
            local g; read -r g < "$_1984_AMD_DEV/gpu_busy_percent"
            [[ $g =~ ^[0-9]+$ ]] && GPU_UTIL=$(( g * 10 ))
        fi
        ;;
      *) return 1 ;;
    esac
    (( VRAM_TOTAL > 0 ))
}

# ─── costruzione della riga di stato ───────────────────────────────────────────
# Scrive in LINE usando le variabili colore già impostate dal chiamante: così la
# stessa riga serve sia al frame a schermo intero sia alla status bar di tmux.
_1984_build_line() {                             # -> LINE
    local SEP="${D} -- ${R}" rp vp
    LINE=''

    _1984_cpu_pct 0
    _1984_col_for "$P_TOT"; _1984_pct_str "$P_TOT"
    LINE+="  ${B}CPU${R} ${COL}${B}${PCT}${R}"

    _1984_busy_cores                             # nota: sovrascrive P_TOT
    _1984_col_for $(( NCPU > 0 ? BUSY * 1000 / NCPU : 0 ))
    LINE+="${SEP}${B}NumC${R} ${COL}${B}${BUSY}/${NCPU}${R}"

    _1984_read_mem
    rp=$(( MemUsed * 1000 / MemTotal ))
    _1984_col_for "$rp"; _1984_pct_str "$rp"
    LINE+="${SEP}${B}${MAG}RAM${R} ${COL}${B}${PCT}${R}"

    if _1984_read_gpu; then
        if (( GPU_UTIL >= 0 )); then
            _1984_col_for "$GPU_UTIL"; _1984_pct_str "$GPU_UTIL"
            LINE+="${SEP}${B}${CYN}GPU${R} ${COL}${B}${PCT}${R}"
        else
            LINE+="${SEP}${B}${CYN}GPU${R} ${D}n/d${R}"
        fi
        vp=$(( VRAM_USED * 1000 / VRAM_TOTAL ))
        _1984_col_for "$vp"; _1984_pct_str "$vp"
        LINE+="${SEP}${B}${CYN}VRAM${R} ${COL}${B}${PCT}${R}"
    else
        LINE+="${SEP}${B}${CYN}GPU${R} ${D}n/d${R}${SEP}${B}${CYN}VRAM${R} ${D}n/d${R}"
    fi
    return 0
}

# ─── rendering di un frame ─────────────────────────────────────────────────────
_1984_render() {
    local LINE=''
    _1984_build_line
    printf '\e[H%b\e[K' "$LINE"
}

# ─── funzione principale ───────────────────────────────────────────────────────
1984() {
    # tutte locali: nulla resta nella shell dopo il ritorno (le ausiliarie le
    # vedono comunque, bash usa scoping dinamico)
    local DELAY=1 FRAMES=0 frame=0 key
    local R=$'\e[0m' B=$'\e[1m' D=$'\e[2m'
    local GRN=$'\e[32m' RED=$'\e[31m' YEL=$'\e[33m' CYN=$'\e[36m' MAG=$'\e[35m'
    local BUSY_THRESHOLD=250                     # 25.0%, in decimi di percento
    local NCPU=0 BUSY=0 P_TOT=0 COL='' PCT=''
    local MemTotal=1 MemFree=0 Buffers=0 Cached=0 SReclaimable=0 Shmem=0
    local CacheTot=0 MemUsed=0
    local VRAM_USED=0 VRAM_TOTAL=0 GPU_UTIL=-1
    local -a cur_total=() cur_idle=() prev_total=() prev_idle=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--delay)  DELAY=$2; shift 2 ;;
            -n|--frames) FRAMES=$2; shift 2 ;;
            -h|--help)   sed -n '3,10p' "${BASH_SOURCE[0]}" | cut -c3-; return 0 ;;
            *) echo "opzione sconosciuta: $1" >&2; return 1 ;;
        esac
    done

    _1984_detect_gpu
    # Ctrl-C: alza un flag che il loop controlla, così si esce dalla funzione
    # senza chiudere la shell (un `return` dentro il trap non interrompe il loop)
    local _int=0
    trap '_int=1' INT
    printf '\e[?25l\e[2J'

    _1984_sample_cpu
    prev_total=("${cur_total[@]}"); prev_idle=("${cur_idle[@]}")

    # con stdin non collegato a un terminale `read -t` ritorna subito (EOF) e il
    # loop girerebbe a velocità piena: in quel caso si usa sleep
    local tty=0; [[ -t 0 ]] && tty=1

    while :; do
        if (( tty )); then
            # attesa interrompibile: 'q' esce subito senza aspettare il refresh
            if read -rsn1 -t "$DELAY" key 2>/dev/null; then
                [[ $key == q || $key == Q ]] && break
            fi
        else
            sleep "$DELAY"
        fi
        (( _int )) && break
        _1984_sample_cpu
        _1984_render
        prev_total=("${cur_total[@]}"); prev_idle=("${cur_idle[@]}")

        ((frame++))
        (( FRAMES > 0 && frame >= FRAMES )) && break
    done

    trap - INT
    printf '\e[?25h\e[0m\n'
    (( _int )) && return 130
    return 0
}

# ─── riga singola, per la status bar di tmux ───────────────────────────────────
# Stampa una riga e termina, invece di ciclare. Il delta CPU è calcolato rispetto
# alla chiamata precedente, il cui campione sta in un file di stato: così non
# serve dormire tra due letture di /proc/stat e ogni invocazione resta istantanea.
# Il file memorizza anche l'esito del probe GPU, che altrimenti si ripeterebbe a
# ogni refresh (nvidia-smi costa un fork).
#
#     1984_status            colori ANSI, per il terminale
#     1984_status --tmux     tag #[...] di tmux, per status-right
1984_status() {
    local R B D GRN RED YEL CYN MAG LINE=''

    case ${1:-} in
        -t|--tmux)
            R='#[default]' B='#[bold]' D='#[fg=colour244,nobold]'
            GRN='#[fg=green]' RED='#[fg=red]' YEL='#[fg=yellow]'
            CYN='#[fg=cyan]' MAG='#[fg=magenta]' ;;
        -a|--ansi|'')
            R=$'\e[0m' B=$'\e[1m' D=$'\e[2m'
            GRN=$'\e[32m' RED=$'\e[31m' YEL=$'\e[33m' CYN=$'\e[36m' MAG=$'\e[35m' ;;
        *) echo "opzione sconosciuta: $1" >&2; return 1 ;;
    esac

    local BUSY_THRESHOLD=250
    local NCPU=0 BUSY=0 P_TOT=0 COL='' PCT=''
    local MemTotal=1 MemFree=0 Buffers=0 Cached=0 SReclaimable=0 Shmem=0
    local CacheTot=0 MemUsed=0
    local VRAM_USED=0 VRAM_TOTAL=0 GPU_UTIL=-1
    local -a cur_total=() cur_idle=() prev_total=() prev_idle=()
    local state="${XDG_RUNTIME_DIR:-$HOME/.cache}/1984-status"

    # il file è sotto $HOME (o nella runtime dir dell'utente), non in /tmp: viene
    # sorgentato, quindi non deve stare in una directory scrivibile da altri
    [[ -d ${state%/*} ]] || mkdir -p "${state%/*}"
    [[ -r $state ]] && source "$state"

    _1984_detect_gpu                             # no-op se lo stato l'ha già impostato
    _1984_sample_cpu
    # prima chiamata (o conteggio core cambiato): delta nullo, niente da fare
    (( ${#prev_total[@]} == ${#cur_total[@]} )) || {
        prev_total=("${cur_total[@]}"); prev_idle=("${cur_idle[@]}")
    }
    printf 'prev_total=(%s)\nprev_idle=(%s)\n_1984_GPU_MODE=%s\n_1984_AMD_DEV=%s\n' \
           "${cur_total[*]}" "${cur_idle[*]}" \
           "$_1984_GPU_MODE" "${_1984_AMD_DEV:-}" > "$state"

    _1984_build_line
    printf '%s\n' "$LINE"
}

# eseguito direttamente invece che sourcato -> lancia subito la funzione
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    1984 "$@"
fi
