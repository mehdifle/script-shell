while getopts k:p: flag
do
    case "${flag}" in
        k) key=${OPTARG};;
        p) port=${OPTARG};;
    esac
done

echo "$key"
echo "$port"

sudo bash <(curl -Ls https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh) -y
sudo apt install jq -y

curl -X GET "https://socket.loobi.us:$port/$key/access-keys" -H "Content-Type: application/json" -o response.json --insecure

Users_json=`jq '.accessKeys' response.json`
Users_length_end=`jq -r ".accessKeys[]| length" response.json|wc -l`
users_length_start=0
while (( $users_length_start < $Users_length_end ))
do
        id=$(echo $Users_json | jq -r ".[$users_length_start].id")
        name=$(echo $Users_json | jq -r ".[$users_length_start].name")
        password=$(echo $Users_json | jq -r ".[$users_length_start].password")
        body='{"name":"'$name'","password":"'$password'","port":51618,"method":"chacha20-ietf-poly1305"}'
        curl -X PUT "https://socket.loobi.us:$port/$key/access-keys/$id" -H "Content-Type: application/json" -d $body --insecure
        users_length_start=`expr $users_length_start + 1`
done