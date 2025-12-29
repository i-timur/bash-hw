declare -i counter=1

while :
do
    echo -n "${counter}, "
    counter+=1

    if (( counter > 100 ))
        then
            break
    fi
done