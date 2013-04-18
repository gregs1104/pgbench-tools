#psql -c "UPDATE testset SET info='$2' WHERE set=$1" -d results
psql -c "INSERT into testset (info) values ('$1')" -d results
