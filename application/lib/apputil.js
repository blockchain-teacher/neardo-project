'use strict';

const fs = require('fs');
const path = require('path');

// ccp 객체화
exports.buildCCPOrg1 = () => {
    const ccpPath = path.resolve(__dirname, '..', 'config', 'connection-org1.json');
    const fileExists = fs.existsSync(ccpPath);
    if(!fileExists) {
        throw new Error(`no such file or directory: ${ccpPath}`);
        return null;
    }
    const contents = fs.readFileSync(ccpPath, 'utf8');
    const ccp = JSON.parse(contents)
    console.log(`Loaded the network configuration located at ${ccpPath}`);
    return ccp;
}

exports.buildCCPOrg2 = () => {
    const ccpPath = path.resolve(__dirname, '..', 'config', 'connection-org2.json');
    const fileExists = fs.existsSync(ccpPath);
    if(!fileExists) {
        throw new Error(`no such file or directory: ${ccpPath}`);
        return null;
    }
    const contents = fs.readFileSync(ccpPath, 'utf8');
    const ccp = JSON.parse(contents)
    console.log(`Loaded the network configuration located at ${ccpPath}`);
    return ccp;
}

// wallet 디렉토리 객체화
exports.buildWallet = async (Wallets, walletPath) => {
    let wallet;
    if(walletPath) {
        wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Built a file system wallet at ${walletPath}`);
    } else {
        wallet = await Wallets.newInMemoryWallet();
        console.log('built an in memory wallet');
    }

    return wallet;
}

exports.prettyJSONString = (inputString) => {
    if(inputString) {
        return JSON.stringify(JSON.parse(inputString), null, 2);
    } else {
        return inputString;
    }
}