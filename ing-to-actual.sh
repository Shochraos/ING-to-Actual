#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: ing-to-actual.sh <inputfile.csv>"
    exit 1
fi

INPUT_RAW="$1"
BASENAME=$(basename "$INPUT_RAW" .csv)
OUTPUT="$(pwd)/${BASENAME}_actual_import.csv"

TMP_UTF8="$(mktemp "${PWD}/${BASENAME}_utf8_XXXX.csv")"
TMP_STRIPPED="$(mktemp "${PWD}/${BASENAME}_stripped_XXXX.csv")"

iconv -f WINDOWS-1252 -t UTF-8 "$INPUT_RAW" -o "$TMP_UTF8"

tail -n +15 "$TMP_UTF8" > "$TMP_STRIPPED"

echo "Date,Payee,Memo,Amount" > "$OUTPUT"

IFS=';'

while read -r buchung wertstellung empfaenger buchungstext verwendungszweck saldo waehrung1 betrag waehrung2; do
    [[ -z "$buchung" || -z "$betrag" ]] && continue

    date=$(echo "$buchung" | sed -E 's#([0-9]{2})\.([0-9]{2})\.([0-9]{4})#\3-\2-\1#')

    payee=$(echo "$empfaenger" | sed 's/"//g')
    memo=$(echo "$verwendungszweck" | sed 's/"//g')

    amount=$(echo "$betrag" | sed -E 's/\.//g; s/,/./; s/-$//')
    [[ "$betrag" =~ -$ ]] && amount="-$amount"

    echo "$date,$payee,$memo,$amount" >> "$OUTPUT"
done < "$TMP_STRIPPED"

rm -f "$TMP_UTF8" "$TMP_STRIPPED"

echo "Created: $OUTPUT"
