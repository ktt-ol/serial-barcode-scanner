#!/bin/bash
FOLDER=passlist

echo "Cleanup..."
rm -rf $FOLDER
mkdir -p $FOLDER

echo "Create user list from db..."
./query.sh $1

echo "Make latex document and images..."
ruby passlist.rb users.csv

echo "Run pdflatex..."
( cd $FOLDER && pdflatex passlist.latex )
