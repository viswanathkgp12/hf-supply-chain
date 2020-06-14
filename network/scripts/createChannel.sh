# Import
. ./envVars.sh

CHANNEL_PROFILE="FourOrgsSupplyChainChannel"
CHANNEL_NAME="fourorgssupplychainchannel"

clean() {
    rm ./channel-artifacts/*.tx
}

createChannelTx() {
    echo
    echo "###################################################################"
    echo "###  Generating channel configuration transaction  '${CHANNEL_NAME}.tx' ###"
    echo "###################################################################"
    set -x
    configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx ./channel-artifacts/$CHANNEL_NAME.tx -channelID $CHANNEL_NAME -configPath $PWD
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate channel configuration transaction..."
        exit 1
    fi
}

createChannel() {

    CA_FILE_ADMIN_USER=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/abacsupplychain.io/orderers/orderer.abacsupplychain.io/msp/tlscacerts/tlsca.abacsupplychain.io-cert.pem

    docker exec cli peer channel create -o orderer.abacsupplychain.io:7050 \
        -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --cafile $CA_FILE_ADMIN_USER --tls true
}

joinChannel() {
    setGlobalsForPeerAndOrg producer.abacsupplychain.io ProducerMSP peer0 8051
    docker exec cli peer channel join -b fourorgssupplychainchannel.block

    setGlobalsForPeerAndOrg shipper.abacsupplychain.io ShipperOrg peer0 9051
    docker exec cli peer channel join -b fourorgssupplychainchannel.block

    setGlobalsForPeerAndOrg regulator.abacsupplychain.io RegulatorOrg peer0 10051
    docker exec cli peer channel join -b fourorgssupplychainchannel.block
}

createAnchorPeerTx() {

    for org in RetailerOrg ProducerOrg ShipperOrg RegulatorOrg; do

        echo
        echo "#####################################################################"
        echo "#######  Generating anchor peer update for ${org}          ##########"
        echo "#####################################################################"
        set -x
        configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate ./channel-artifacts/${org}Anchors.tx -channelID $CHANNEL_NAME -asOrg ${org} -configPath $PWD
        res=$?
        set +x
        if [ $res -ne 0 ]; then
            echo "Failed to generate anchor peer update for ${org}..."
            exit 1
        fi

    done
}

clean
createChannelTx
createChannel
joinChannel