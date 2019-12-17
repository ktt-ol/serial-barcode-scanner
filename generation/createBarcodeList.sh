#!/bin/bash
cd $(dirname "$0")

FOLDER=barcodes

echo "Cleanup..."
rm -rf $FOLDER
mkdir -p $FOLDER

echo "Create user list from db..."
./query.sh $1

echo "Make latex document and images..."
ruby barcodelist.rb users.csv

echo "Run pdflatex..."
( cd $FOLDER && pdflatex barcode.latex )
