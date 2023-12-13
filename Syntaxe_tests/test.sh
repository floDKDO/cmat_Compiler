#!/bin/bash
Dir=$(dirname $0)
#Accept

echo -e "\033[0m\nAccept directory\n"

ListeFile="$(find ${Dir}/Accept/* -type f)"
for File in ${ListeFile}; do
	${Dir}/../cmat < "${File}" >/dev/null 2>&1
	if [ $? -eq 0 ] ; 
	then 
		echo -e "\033[0;32mTest passed $(echo "${File}" | cut -d'/' -f3-)"
	else
		echo -e "\033[0;31mTest failed $(echo "${File}" | cut -d'/' -f3-)"
	fi
done

#Reject

echo -e "\033[0m\nError directory\n"

ListeFile="$(find ${Dir}/Error/* -type f)"
for File in ${ListeFile}; do
	${Dir}/../cmat < "${File}" >/dev/null 2>&1
	if [ $? -eq 1 ] ; 
	then 
		echo -e "\033[0;32mTest passed $(echo "${File}" | cut -d'/' -f3-)"
	else
		echo -e "\033[0;31mTest failed $(echo "${File}" | cut -d'/' -f3-)"
	fi
done
