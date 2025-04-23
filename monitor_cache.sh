#!/bin/bash


# ./monitor_cache.sh -c "./my_program" -d 10

# Fungsi untuk menampilkan help
function show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c <command>    : Perintah yang ingin dianalisis (misalnya, './my_program')"
    echo "  -p <pid>        : PID proses yang ingin dipantau (misalnya, '1234')"
    echo "  -d <duration>    : Durasi dalam detik untuk pemantauan (misalnya, '10')"
    echo "  -r               : Rekam event cache dan simpan ke file"
    echo "  -h               : Tampilkan bantuan ini"
    echo ""
}

# Mengecek apakah parameter sudah diterima
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Variabel default
COMMAND=""
PID=""
DURATION=10
RECORD=false

# Parse argument yang diberikan
while getopts ":c:p:d:rh" opt; do
    case $opt in
        c) COMMAND="$OPTARG" ;;
        p) PID="$OPTARG" ;;
        d) DURATION="$OPTARG" ;;
        r) RECORD=true ;;
        h) show_help; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG"; show_help; exit 1 ;;
    esac
done

# Pastikan kita memiliki perintah atau PID untuk dianalisis
if [ -z "$COMMAND" ] && [ -z "$PID" ]; then
    echo "Error: Harus menyertakan -c <command> atau -p <pid>"
    show_help
    exit 1
fi

# Fungsi untuk melakukan rekaman dengan perf
function record_perf() {
    if [ "$RECORD" = true ]; then
        if [ -n "$COMMAND" ]; then
            echo "Merekam event cache untuk perintah '$COMMAND'..."
            perf record -e cache-references,cache-misses $COMMAND
        elif [ -n "$PID" ]; then
            echo "Merekam event cache untuk proses PID $PID..."
            perf record -e cache-references,cache-misses -p $PID
        fi
        echo "Rekaman selesai. Gunakan 'perf report' untuk analisis lebih lanjut."
    fi
}

# Fungsi untuk memantau cache dengan perf stat
function stat_perf() {
    echo "Memantau cache dengan 'perf stat'..."

    if [ -n "$COMMAND" ]; then
        perf stat -e cache-references,cache-misses $COMMAND
    elif [ -n "$PID" ]; then
        perf stat -e cache-references,cache-misses -p $PID
    fi
}

# Fungsi untuk memantau cache selama durasi tertentu
function monitor_duration() {
    echo "Memantau cache selama $DURATION detik..."
    if [ -n "$COMMAND" ]; then
        perf stat -e cache-references,cache-misses $COMMAND sleep $DURATION
    elif [ -n "$PID" ]; then
        perf stat -e cache-references,cache-misses -p $PID sleep $DURATION
    fi
}

# Menjalankan fungsi yang sesuai berdasarkan input
if [ "$RECORD" = true ]; then
    record_perf
else
    monitor_duration
    stat_perf
fi
