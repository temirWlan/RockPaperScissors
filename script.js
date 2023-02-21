const contractAddress = "0xb1489AefDaf1042081493E900fBCe59b5c28a80d";
const contractABI = [
	{
		"inputs": [
			{
				"internalType": "uint8",
				"name": "_option",
				"type": "uint8"
			}
		],
		"name": "makeMove",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [],
		"stateMutability": "payable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"internalType": "address",
				"name": "player",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint8",
				"name": "option",
				"type": "uint8"
			},
			{
				"indexed": false,
				"internalType": "bool",
				"name": "result",
				"type": "bool"
			}
		],
		"name": "MoveMade",
		"type": "event"
	},
	{
		"inputs": [],
		"name": "withdraw",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];

const provider = new ethers.providers.Web3Provider(window.ethereum, 97);
let signer;
let contract;


const event = "MoveMade";

provider.send("eth_requestAccounts", []).then(()=>{
    provider.listAccounts().then( (accounts) => {
        signer = provider.getSigner(accounts[0]); //account in metamask
        
        contract = new ethers.Contract(
            contractAddress,
            contractABI,
            signer
        )
     
    }
    )
}
)

async function makeMove(_option){
    let amountInEth = document.getElementById("bet").value;
    console.log(amountInEth)
    let amountInWei = ethers.utils.parseEther(amountInEth.toString())
    console.log(amountInWei);
    
    let resultOfMove = await contract.makeMove(_option, {value: amountInWei});
    const res = await resultOfMove.wait();
    console.log(res);
    //console.log( await res.events[0].args.player.toString());

    let queryResult =  await contract.queryFilter('MoveMade', await provider.getBlockNumber() - 10000, await provider.getBlockNumber());
    let queryResultRecent = queryResult[queryResult.length-1]
    //console.log(queryResult[queryResult.length-1].args);

    let amount = await queryResultRecent.args.amount.toString();
    let player = await queryResultRecent.args.player.toString();
    let option = await queryResultRecent.args.option.toString();
    let result = await queryResultRecent.args.result.toString();
    let playerChose;

    switch (option) {
        case 0:
            playerChose = "Rock";
            break;
        case 1:
            playerChose = "Paper";
            break;
        case 2:
            playerChose = "Scissors";
            break;
    }

    let resultLogs = `
    stake amount: ${ethers.utils.formatEther(amount.toString())} BNB, 
    player: ${player}, 
    player chose: ${playerChose}, 
    result: ${result == false ? "LOSE 😥": "WIN 🎉"}`;
    console.log(resultLogs);

    let resultLog = document.getElementById("result-log");
    resultLog.innerText = resultLogs;

    handleEvent();
}

async function handleEvent(){

    //console.log(await contract.filters.MoveMade());
    let queryResult =  await contract.queryFilter('MoveMade', await provider.getBlockNumber() - 10000, await provider.getBlockNumber());
    let queryResultRecent = queryResult[queryResult.length-1]
    let amount = await queryResultRecent.args.amount.toString();
    let player = await queryResultRecent.args.player.toString();
    let option = await queryResultRecent.args.option.toString();
    let result = await queryResultRecent.args.result.toString();
    let playerChose;

    switch (option) {
        case 0:
            playerChose = "Rock";
            break;
        case 1:
            playerChose = "Paper";
            break;
        case 2:
            playerChose = "Scissors";
            break;
    }

    let resultLogs = `
    stake amount: ${ethers.utils.formatEther(amount.toString())} BNB, 
    player: ${player}, 
    player chose: ${playerChose}, 
    result: ${result == false ? "LOSE 😥": "WIN 🎉"}`;
    console.log(resultLogs);

    let resultLog = document.getElementById("result-log");
    resultLog.innerText = resultLogs;
    
}