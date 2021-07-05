const path = require('path')
const solc = require('solc')
const fs = require('fs-extra')

// remove dir folder
const buildPath = path.resolve(__dirname,'build')
fs.removeSync(buildPath)

// recreate dir forlder
fs.ensureDirSync(buildPath)

// import solidity
const campaignName = 'Campaign'
const campaignFile = campaignName+'.sol'
const campaignPath = path.resolve(__dirname, 'contracts', campaignFile)

const source = fs.readFileSync(campaignPath,'utf-8') 

const input = {
    language: 'Solidity',
    sources: {
      [campaignFile]: {
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
 const contracts = parsed.contracts[campaignFile]

for (const contract in contracts) {
  if (Object.hasOwnProperty.call(contracts, contract)) {
    fs.outputJsonSync(path.resolve(buildPath, contract+'.json'), contracts[contract])
  }
}
