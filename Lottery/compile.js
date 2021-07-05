const path = require('path')
const fs = require('fs')
const solc = require('solc')

const contractName = 'Lottery'
const contractFile = contractName+'.sol'
const contractPath = path.resolve(__dirname,'contracts',contractFile)
const source = fs.readFileSync(contractPath,'utf-8') 

const input = {
    language: 'Solidity',
    sources: {
      [contractFile]: {
          content: source,
       },
    },
    settings: {
       outputSelection: {
          '*': {
             '*': ['*'],
          },
       },
    },
 };
 const parsed = JSON.parse(solc.compile(JSON.stringify(input)));
 const contract = parsed.contracts[contractFile][contractName];

 module.exports = contract;